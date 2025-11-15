class StorageConfig {
  static Map<String, dynamic> get config => {
        'default': 'local',
        'disks': {
          'local': {
            'driver': 'local',
            'root': 'storage',
          },
          'public': {
            'driver': 'local',
            'root': 'public/assets',
          },
        },
      };
}
