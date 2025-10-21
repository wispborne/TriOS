/// Note that success and error are not mutually exclusive. Maybe there was an error but the operation was still successful.
class Result {
  final bool wasSuccessful;
  final List<Exception> errors;

  Result(this.wasSuccessful, this.errors);

  static Result unmitigatedSuccess() => Result(true, []);
  static Result unmitigatedFailure(List<Exception> errors) => Result(false, errors);
  static Result partialSuccess(List<Exception> errors) => Result(true, errors);
}
