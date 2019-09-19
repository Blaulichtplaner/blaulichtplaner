abstract class Loadable {
  bool loading = false;

  startLoading() {
    loading = true;
  }

  finishLoading() {
    loading = false;
  }
}
