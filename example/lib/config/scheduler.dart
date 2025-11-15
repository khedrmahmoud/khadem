class SchedulerConfig {
  static Map<String, dynamic> get config => {
        'tasks': [
          {
            'name': 'cache_clean_config',
            'job': 'ttl_cleaner',
            'interval': 600,
            'retryOnFail': false,
            'cachePath': 'storage/cache',
          },
        ],
      };
}
