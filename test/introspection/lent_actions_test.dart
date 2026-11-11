import 'package:stacked_shared/stacked_introspection.dart';
import 'package:test/test.dart';

class _Provider extends LentActionProvider {
  _Provider(this.id, {this.isActive = true});

  @override
  final String id;

  @override
  bool isActive;

  @override
  Map<String, Object?>? get overlay => {'type': id};

  @override
  List<ActionSpec> get actions => [ActionSpec(name: '$id-action')];
}

void main() {
  setUp(LentActionProviders.reset);
  tearDown(LentActionProviders.reset);

  test('active filters on isActive, in registration order', () {
    final dialog = _Provider('dialog');
    final sheet = _Provider('sheet', isActive: false);
    final snack = _Provider('snackbar');
    LentActionProviders.register(dialog);
    LentActionProviders.register(sheet);
    LentActionProviders.register(snack);

    expect(LentActionProviders.active.map((p) => p.id), ['dialog', 'snackbar']);

    sheet.isActive = true;
    expect(LentActionProviders.active.map((p) => p.id),
        ['dialog', 'sheet', 'snackbar']);
  });

  test('re-registering the same id replaces it and moves it to the end', () {
    final first = _Provider('dialog');
    final other = _Provider('sheet');
    final second = _Provider('dialog');
    LentActionProviders.register(first);
    LentActionProviders.register(other);
    LentActionProviders.register(second);

    final active = LentActionProviders.active;
    expect(active, hasLength(2));
    expect(active.first, same(other));
    expect(active.last, same(second));
  });

  test('unregister removes by id', () {
    LentActionProviders.register(_Provider('dialog'));
    LentActionProviders.register(_Provider('sheet'));
    LentActionProviders.unregister('dialog');
    expect(LentActionProviders.active.map((p) => p.id), ['sheet']);
    LentActionProviders.unregister('missing');
    expect(LentActionProviders.active, hasLength(1));
  });

  test('reset removes everything', () {
    LentActionProviders.register(_Provider('dialog'));
    LentActionProviders.reset();
    expect(LentActionProviders.active, isEmpty);
  });
}
