 

import '../../../contracts/database/connection_interface.dart';
import '../../../contracts/database/database_factory_interface.dart';
import 'mysql_schema_builder.dart';
import 'mysql_connection.dart';

/// MySQL database factory + driver implementation.
class MySQLDriver implements DatabaseFactoryInterface {
  @override
  ConnectionInterface createConnection(Map<String, dynamic> config) {
    return MySQLConnection(config);
  }

  @override
  MySQLSchemaBuilder createSchemaBuilder() {
    return MySQLSchemaBuilder();
  }
}
