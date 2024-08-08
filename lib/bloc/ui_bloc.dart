import 'dart:async';
import 'package:bloc/bloc.dart';

sealed class UIEvent {}

class UIDragStarted extends UIEvent {}

class UIDragStopped extends UIEvent {}

class UICurrentTimeTicked extends UIEvent {
  UICurrentTimeTicked({required this.currentTime});
  final DateTime currentTime;
}

class UIDurationPickerShown extends UIEvent {
  UIDurationPickerShown({required this.duration});
  final Duration duration;
}

class UIDurationPickerUpdated extends UIEvent {
  UIDurationPickerUpdated({required this.duration});
  final Duration duration;
}

class UIDurationPickerHidden extends UIEvent {
  UIDurationPickerHidden();
}

class UITimePickerShown extends UIEvent {
  UITimePickerShown({required this.time});
  final DateTime time;
}

class UITimePickerUpdated extends UIEvent {
  UITimePickerUpdated({required this.time});
  final DateTime time;
}

class UITimePickerHidden extends UIEvent {
  UITimePickerHidden();
}

class UISomeTitleFocused extends UIEvent {
  UISomeTitleFocused();
}

class UINoTitleFocused extends UIEvent {
  UINoTitleFocused();
}

class UIState {
  UIState({
    isEditingSomeTitle = false,
    isDragging = false,
    DateTime? currentTime,
    Duration? pickerDuration,
    DateTime? pickerTime,
  }) : _isEditingSomeTitle=isEditingSomeTitle, _isDragging = isDragging, _currentTime = currentTime ?? DateTime.now(), _pickerDuration = pickerDuration, _pickerTime = pickerTime;

  bool get canScroll => _pickerDuration == null && _pickerTime == null;
  bool get isDragging => _isDragging;
  DateTime get currentTime => _currentTime;
  Duration? get pickerDuration => _pickerDuration;
  DateTime? get pickerTime => _pickerTime;
  bool get isEditingSomeDuration => _pickerDuration != null;
  bool get isEditingSomeTitle => _isEditingSomeTitle;
  bool get isEditingSomeStartTime => _pickerTime != null;

  final bool _isEditingSomeTitle;
  final bool _isDragging;
  final DateTime _currentTime;
  final Duration? _pickerDuration;
  final DateTime? _pickerTime;

  UIState resetPickers() {
    return UIState(
      isEditingSomeTitle: _isEditingSomeTitle,
      isDragging: _isDragging,
      currentTime: _currentTime,
      pickerDuration: null,
      pickerTime: null,
    );
  }

  UIState copyWith({
    bool? isEditingSomeTitle,
    bool? isDragging,
    DateTime? currentTime,
    Duration? pickerDuration,
    DateTime? pickerTime,
  }) {
    return UIState(
      isEditingSomeTitle: isEditingSomeTitle ?? _isEditingSomeTitle,
      isDragging: isDragging ?? this.isDragging,
      currentTime: currentTime ?? this.currentTime,
      pickerDuration: pickerDuration ?? this.pickerDuration,
      pickerTime: pickerTime ?? this.pickerTime,
    );
  }
}

Stream<DateTime> currentTime() => Stream.periodic(const Duration(seconds: 10), (_) => DateTime.now());

class UIBloc extends Bloc<UIEvent, UIState> {
  late final StreamSubscription _currentTimeSubscription;

  UIBloc() : super(UIState()) {
    _currentTimeSubscription = currentTime().listen((DateTime dt) => add(UICurrentTimeTicked(currentTime: dt)));
    on<UICurrentTimeTicked>((event, emit) => emit(state.copyWith(currentTime: event.currentTime)));

    on<UIDragStarted>((event, emit) => emit(state.copyWith(isDragging: true)) );
    on<UIDragStopped>((event, emit) => emit(state.copyWith(isDragging: false)) );
    on<UIDurationPickerShown>((event, emit) => emit(state.copyWith(pickerDuration: event.duration)));
    on<UIDurationPickerUpdated>((event, emit) => emit(state.copyWith(pickerDuration: event.duration)));
    on<UIDurationPickerHidden>((event, emit) => emit(state.resetPickers())); 
    on<UITimePickerShown>((event, emit) => emit(state.copyWith(pickerTime: event.time)));
    on<UITimePickerUpdated>((event, emit) => emit(state.copyWith(pickerTime: event.time)));
    on<UITimePickerHidden>((event, emit) => emit(state.resetPickers()));
    on<UISomeTitleFocused>((event, emit) => emit(state.copyWith(isEditingSomeTitle: true)));
    on<UINoTitleFocused>((event, emit) => emit(state.copyWith(isEditingSomeTitle: false)));
  }

  @override
  Future<void> close() {
    _currentTimeSubscription.cancel();
    return super.close();
  }

}
