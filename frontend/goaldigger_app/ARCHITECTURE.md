# GoalDigger App Architecture

The Flutter app follows **MVVM** with a layered structure, based on
[Flutter's app architecture guide](https://docs.flutter.dev/app-architecture).
Dependencies only point downward: `ui → data → core`.

```
lib/
├── main.dart                 # bootstrap: config → Supabase → providers → app
├── app/
│   ├── app.dart              # MaterialApp
│   └── dependencies.dart     # composition root (all providers)
├── core/                     # framework-agnostic, no feature knowledge
│   ├── config/               # AppConfig (.env)
│   ├── errors/               # AppException, describeError
│   ├── result/               # Result<T>, guard()
│   ├── theme/                # AppColors, AppTheme
│   └── utils/                # Formatters, Validators, Parallel
├── data/
│   ├── models/               # DTOs + domain rules (Goal, SplitExpense…)
│   ├── repositories/<domain>/
│   │   ├── *_repository.dart         # abstract contract
│   │   └── *_repository_remote.dart  # REST implementation
│   └── services/
│       ├── api/api_client.dart       # HTTP transport only
│       ├── realtime/                 # Supabase change streams
│       └── data_change_notifier.dart # "this client wrote data"
└── ui/
    ├── core/                 # ViewModel base, mixins, shared widgets
    ├── session/              # SessionViewModel + AuthGate
    ├── home/                 # HomeShell (tabs, per-user view models)
    └── <feature>/            # auth, ledger, goals, stats, split, settings
        ├── view_models/
        ├── views/            # screens
        └── widgets/          # feature widgets, sheets, dialogs
```

## Responsibilities

| Layer | Owns | Must not |
|---|---|---|
| **View** (`views/`, `widgets/`) | Layout, `TextEditingController`s, navigation, snack bars | Call repositories, hold business state |
| **ViewModel** | Screen state, optimistic updates + rollback, validation, commands returning `Result` | Import `material.dart`, hold a `BuildContext` |
| **Repository** | Endpoint paths, JSON mapping, firing `DataChangeNotifier` after writes | Hold UI state |
| **Service** | Transport (HTTP, realtime) | Know about specific endpoints |

## Conventions

- **State loading** – view models mix in `LoadStateMixin` and call
  `runLoad(fetch, commit, silent: …)`. It manages `isLoading` /
  `isRefreshing` / `errorMessage` and discards stale responses.
- **Auto refresh** – `AutoRefreshMixin.listenToDataChanges` (local writes) and
  `watchRealtime` (backend changes). Both are released in `dispose`.
- **Commands** return `Future<Result<T>>`; views switch on
  `Success` / `Failure` to pick the message:
  ```dart
  final messenger = ScaffoldMessenger.of(context); // capture before await
  final result = await viewModel.delete(goal);
  messenger.showMessage(switch (result) {
    Success() => '已刪除 ${goal.title}',
    Failure(:final message) => message,
  });
  ```
- **Sheets & dialogs** return a value with `Navigator.pop` (a draft or an
  action enum); the screen passes it to the view model.
- **Scoping** – app-wide objects live in `app/dependencies.dart`; per-user
  view models are created in `HomeShell`; screen-local view models (group
  detail, expense editor, settlement) are created where the route or sheet
  is opened.

## Adding a feature

1. Add a model under `data/models/` and a repository contract plus a remote
   implementation under `data/repositories/<domain>/`.
2. Register the repository in `app/dependencies.dart` by its abstract type.
3. Create `ui/<feature>/view_models/<feature>_view_model.dart` that extends
   `ViewModel` and takes repositories through its constructor.
4. Build the screen with `context.watch<FeatureViewModel>()`.
5. Add tests under `test/` using the fakes in `test/helpers/fakes.dart`.

## Testing

```bash
cp .env.example .env   # .env is a declared asset and must exist to build
flutter analyze
flutter test
```
