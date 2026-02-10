class SchedulerConfig {
  static Map<String, dynamic> get config => {
        'tasks': [
          // Example task configuration:
          // {
          //   'name': 'ping_from_config',
          //   'job': 'ping',
          //   'interval': 600,
          //   'retryOnFail': true,
          // },
          // {
          //   'name': 'cache_clean_config',
          //   'job': 'ttl_cleaner',
          //   'interval': 600,
          //   'retryOnFail': false,
          //   'cachePath': 'storage/cache',
          // },
        ],
      };
}
