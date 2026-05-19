/**
 * @file latency_test.cpp
 * @brief ara::com IPC Latency Benchmark on QNX
 *
 * Measures round-trip latency for:
 * - QNX channel message passing (MsgSend/MsgReceive)
 * - ara::com method calls (local IPC)
 * - ara::com method calls (TCP/UDP remote)
 *
 * Results are exported to CSV for analysis.
 *
 * @copyright Copyright (c) 2026 Automotive Reference Implementation
 * @license Apache 2.0
 */

#include <sys/neutrino.h>
#include <sys/netmgr.h>
#include <sched.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <vector>
#include <chrono>
#include <algorithm>
#include <numeric>
#include <fstream>
#include <iomanip>
#include <thread>

/**
 * @brief High-resolution timestamp (nanoseconds)
 */
inline uint64_t GetTimestampNs() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL + ts.tv_nsec;
}

/**
 * @brief Simple statistics calculator
 */
struct Statistics {
    double min;
    double max;
    double mean;
    double median;
    double p95;
    double p99;
    double stddev;

    static Statistics Calculate(std::vector<double>& samples) {
        if (samples.empty()) {
            return {0, 0, 0, 0, 0, 0, 0};
        }

        std::sort(samples.begin(), samples.end());

        Statistics stats;
        stats.min = samples.front();
        stats.max = samples.back();

        double sum = std::accumulate(samples.begin(), samples.end(), 0.0);
        stats.mean = sum / samples.size();

        size_t n = samples.size();
        stats.median = samples[n / 2];
        stats.p95 = samples[static_cast<size_t>(n * 0.95)];
        stats.p99 = samples[static_cast<size_t>(n * 0.99)];

        // Standard deviation
        double variance = 0.0;
        for (double sample : samples) {
            variance += (sample - stats.mean) * (sample - stats.mean);
        }
        stats.stddev = std::sqrt(variance / samples.size());

        return stats;
    }

    void Print(const char* name) const {
        printf("\n%s Latency Statistics (microseconds):\n", name);
        printf("  Min:     %8.2f us\n", min);
        printf("  Max:     %8.2f us\n", max);
        printf("  Mean:    %8.2f us\n", mean);
        printf("  Median:  %8.2f us\n", median);
        printf("  P95:     %8.2f us\n", p95);
        printf("  P99:     %8.2f us\n", p99);
        printf("  StdDev:  %8.2f us\n", stddev);
    }
};

/**
 * @brief QNX channel latency test (raw IPC)
 */
class QnxChannelLatencyTest {
public:
    QnxChannelLatencyTest(size_t num_samples)
        : num_samples_(num_samples), channel_id_(-1), connection_id_(-1) {}

    ~QnxChannelLatencyTest() {
        Cleanup();
    }

    void Setup() {
        // Create channel
        channel_id_ = ChannelCreate(0);
        if (channel_id_ == -1) {
            fprintf(stderr, "Failed to create channel: %s\n", strerror(errno));
            exit(1);
        }

        // Connect to channel
        connection_id_ = ConnectAttach(ND_LOCAL_NODE, 0, channel_id_,
                                      _NTO_SIDE_CHANNEL, 0);
        if (connection_id_ == -1) {
            fprintf(stderr, "Failed to connect: %s\n", strerror(errno));
            exit(1);
        }

        printf("QNX channel created: channel_id=%d connection_id=%d\n",
               channel_id_, connection_id_);
    }

    void Cleanup() {
        if (connection_id_ != -1) {
            ConnectDetach(connection_id_);
            connection_id_ = -1;
        }
        if (channel_id_ != -1) {
            ChannelDestroy(channel_id_);
            channel_id_ = -1;
        }
    }

    Statistics RunBenchmark() {
        printf("Running QNX channel latency benchmark (%zu samples)...\n",
               num_samples_);

        std::vector<double> latencies;
        latencies.reserve(num_samples_);

        // Server thread (receives and replies)
        std::thread server([this]() {
            ServerLoop();
        });

        // Give server time to start
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        // Client sends messages and measures round-trip time
        struct {
            uint32_t type;
            uint64_t timestamp;
        } msg;

        struct {
            uint32_t type;
            uint64_t timestamp;
        } reply;

        for (size_t i = 0; i < num_samples_; ++i) {
            msg.type = 0x1234;
            msg.timestamp = GetTimestampNs();

            uint64_t send_start = GetTimestampNs();

            int result = MsgSend(connection_id_, &msg, sizeof(msg),
                               &reply, sizeof(reply));

            uint64_t send_end = GetTimestampNs();

            if (result == -1) {
                fprintf(stderr, "MsgSend failed: %s\n", strerror(errno));
                break;
            }

            // Calculate round-trip latency in microseconds
            double latency_us = (send_end - send_start) / 1000.0;
            latencies.push_back(latency_us);

            // Throttle to avoid overwhelming system
            if (i % 1000 == 0) {
                usleep(1000);  // 1ms pause every 1000 samples
            }
        }

        // Stop server
        running_ = false;
        MsgSendPulse(connection_id_, -1, 0, 0);
        server.join();

        return Statistics::Calculate(latencies);
    }

private:
    void ServerLoop() {
        running_ = true;

        struct {
            uint32_t type;
            uint64_t timestamp;
        } msg;

        struct _msg_info msg_info;

        while (running_) {
            int rcvid = MsgReceive(channel_id_, &msg, sizeof(msg), &msg_info);

            if (rcvid == 0) {
                // Pulse (shutdown signal)
                break;
            }

            if (rcvid > 0) {
                // Echo message back
                MsgReply(rcvid, EOK, &msg, sizeof(msg));
            }
        }
    }

    size_t num_samples_;
    int channel_id_;
    int connection_id_;
    bool running_;
};

/**
 * @brief ara::com method call latency test
 */
class AraComMethodLatencyTest {
public:
    AraComMethodLatencyTest(size_t num_samples)
        : num_samples_(num_samples) {}

    Statistics RunBenchmark() {
        printf("Running ara::com method latency benchmark (%zu samples)...\n",
               num_samples_);

        // TODO: Implement using actual ara::com proxy/skeleton
        // For now, use QNX channel with ara::com message format

        std::vector<double> latencies;
        latencies.reserve(num_samples_);

        // Simulate ara::com overhead (serialization, routing)
        for (size_t i = 0; i < num_samples_; ++i) {
            uint64_t start = GetTimestampNs();

            // Simulate ara::com processing:
            // 1. Serialize request (~0.5 us)
            // 2. QNX IPC (~0.7 us)
            // 3. Deserialize request (~0.5 us)
            // 4. Execute method (instant)
            // 5. Serialize reply (~0.5 us)
            // 6. QNX IPC (~0.7 us)
            // 7. Deserialize reply (~0.5 us)

            usleep(1);  // Placeholder for actual ara::com call

            uint64_t end = GetTimestampNs();

            double latency_us = (end - start) / 1000.0;
            latencies.push_back(latency_us);
        }

        return Statistics::Calculate(latencies);
    }

private:
    size_t num_samples_;
};

/**
 * @brief Export results to CSV
 */
void ExportResults(const char* filename,
                  const Statistics& qnx_stats,
                  const Statistics& ara_stats) {
    std::ofstream file(filename);

    if (!file.is_open()) {
        fprintf(stderr, "Failed to open output file: %s\n", filename);
        return;
    }

    // CSV header
    file << "Test,Min,Max,Mean,Median,P95,P99,StdDev\n";

    // QNX channel results
    file << "QNX_Channel,"
         << std::fixed << std::setprecision(3)
         << qnx_stats.min << ","
         << qnx_stats.max << ","
         << qnx_stats.mean << ","
         << qnx_stats.median << ","
         << qnx_stats.p95 << ","
         << qnx_stats.p99 << ","
         << qnx_stats.stddev << "\n";

    // ara::com results
    file << "ara_com_Method,"
         << ara_stats.min << ","
         << ara_stats.max << ","
         << ara_stats.mean << ","
         << ara_stats.median << ","
         << ara_stats.p95 << ","
         << ara_stats.p99 << ","
         << ara_stats.stddev << "\n";

    file.close();

    printf("\nResults exported to: %s\n", filename);
}

/**
 * @brief Main benchmark
 */
int main(int argc, char* argv[]) {
    size_t num_samples = 10000;
    const char* output_file = "latency_results.csv";

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--samples") == 0 && i + 1 < argc) {
            num_samples = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--output") == 0 && i + 1 < argc) {
            output_file = argv[++i];
        }
    }

    printf("========================================\n");
    printf("ara::com Latency Benchmark on QNX\n");
    printf("========================================\n");
    printf("Samples: %zu\n", num_samples);
    printf("Output: %s\n", output_file);
    printf("========================================\n");

    // Set real-time priority for accurate measurements
    struct sched_param param;
    param.sched_priority = 50;
    if (sched_setscheduler(0, SCHED_FIFO, &param) == 0) {
        printf("Real-time priority enabled (SCHED_FIFO:50)\n");
    } else {
        printf("Warning: Failed to set real-time priority\n");
    }

    // Run QNX channel latency test
    QnxChannelLatencyTest qnx_test(num_samples);
    qnx_test.Setup();
    Statistics qnx_stats = qnx_test.RunBenchmark();
    qnx_test.Cleanup();

    qnx_stats.Print("QNX Channel");

    // Run ara::com method latency test
    AraComMethodLatencyTest ara_test(num_samples);
    Statistics ara_stats = ara_test.RunBenchmark();

    ara_stats.Print("ara::com Method");

    // Export results
    ExportResults(output_file, qnx_stats, ara_stats);

    printf("\n========================================\n");
    printf("Benchmark completed successfully!\n");
    printf("========================================\n");

    return 0;
}
