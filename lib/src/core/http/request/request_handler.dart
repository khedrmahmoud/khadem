import 'dart:async';

import 'request.dart';
import '../response/response.dart';

/// A handler is a function that takes in a [Request] and [Response] and performs
/// any necessary logic to complete the request. This can include database
/// interactions, business logic, or any other type of computation.
///
/// Handlers are the core of the Khadem framework. They are used to
/// handle HTTP requests and return an appropriate response.
///
/// The handler function will be called with a [Request] and [Response] object.
/// The request object contains information about the incoming HTTP request,
/// such as the URL, headers, and body. The response object is used to send
/// a response back to the client.
///
/// The handler function should use the request object to figure out what
/// to do, and then use the response object to send the result back to the
/// client.
typedef RequestHandler = FutureOr<void> Function(Request request, Response response);
