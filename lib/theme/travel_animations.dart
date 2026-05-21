import 'package:flutter/material.dart';

/// Sistema de animações do Travel Planner
///
/// Animações customizadas para dar vida ao app
/// Substitui animações genéricas por transições temáticas
class TravelAnimations {
  // ============================================================================
  // DURAÇÕES PADRÃO
  // ============================================================================

  /// Duração rápida - 200ms
  static const Duration fast = Duration(milliseconds: 200);

  /// Duração normal - 300ms
  static const Duration normal = Duration(milliseconds: 300);

  /// Duração lenta - 500ms
  static const Duration slow = Duration(milliseconds: 500);

  /// Duração muito lenta - 800ms
  static const Duration verySlow = Duration(milliseconds: 800);

  // ============================================================================
  // CURVAS DE ANIMAÇÃO
  // ============================================================================

  /// Curva suave - Entrada e saída suaves
  static const Curve smooth = Curves.easeInOutCubic;

  /// Curva elástica - Efeito de mola
  static const Curve elastic = Curves.elasticOut;

  /// Curva bounce - Efeito de quique
  static const Curve bounce = Curves.bounceOut;

  /// Curva rápida - Aceleração rápida
  static const Curve fastOut = Curves.easeOutExpo;

  // ============================================================================
  // TRANSIÇÕES DE PÁGINA
  // ============================================================================

  /// Transição de slide da direita (padrão iOS)
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: smooth),
        );
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Transição de slide de baixo para cima
  static PageRouteBuilder<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: smooth),
        );
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Transição de fade (desvanecimento)
  static PageRouteBuilder<T> fade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Transição de escala (zoom)
  static PageRouteBuilder<T> scale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: smooth),
        );
        final scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Transição combinada (slide + fade)
  static PageRouteBuilder<T> slideAndFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.3, 0.0);
        const end = Offset.zero;
        final slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: smooth),
        );
        final slideAnimation = animation.drive(slideTween);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================================
  // ANIMAÇÕES DE WIDGETS
  // ============================================================================

  /// Animação de entrada com slide de baixo
  static Widget slideInFromBottom({
    required Widget child,
    Duration? duration,
    Curve? curve,
    Duration? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 50.0, end: 0.0),
      duration: duration ?? normal,
      curve: curve ?? smooth,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1 - (value / 50),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Animação de entrada com fade
  static Widget fadeIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
    Duration? delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? normal,
      curve: curve ?? Curves.easeIn,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Animação de escala (zoom in)
  static Widget scaleIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: duration ?? normal,
      curve: curve ?? elastic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Animação de bounce (quique)
  static Widget bounceIn({
    required Widget child,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? slow,
      curve: bounce,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Animação de shimmer (loading)
  static Widget shimmer({
    required Widget child,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration ?? const Duration(milliseconds: 1500),
      curve: Curves.linear,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                value - 0.3,
                value,
                value + 0.3,
              ],
              colors: const [
                Color(0xFFEBEBF4),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBF4),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  // ============================================================================
  // MICRO-INTERAÇÕES
  // ============================================================================

  /// Efeito de pulso (para notificações)
  static Widget pulse({
    required Widget child,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.1),
      duration: duration ?? const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // Loop infinito
      },
      child: child,
    );
  }

  /// Efeito de shake (para erros)
  static Widget shake({
    required Widget child,
    Duration? duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? const Duration(milliseconds: 500),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        final offset = (value < 0.5 ? value : 1 - value) * 10;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Efeito de rotação
  static Widget rotate({
    required Widget child,
    Duration? duration,
    bool infinite = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? const Duration(seconds: 2),
      curve: Curves.linear,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }

  // ============================================================================
  // ANIMAÇÕES DE LISTA
  // ============================================================================

  /// Animação escalonada para listas
  static Widget staggeredList({
    required List<Widget> children,
    Duration? staggerDelay,
    Duration? itemDuration,
  }) {
    final delay = staggerDelay ?? const Duration(milliseconds: 50);
    final duration = itemDuration ?? normal;

    return Column(
      children: List.generate(
        children.length,
        (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: duration,
            curve: smooth,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: children[index],
          );
        },
      ),
    );
  }
}

/// Widget helper para animações de entrada
class AnimatedEntry extends StatelessWidget {
  final Widget child;
  final Duration? delay;
  final Duration? duration;
  final Curve? curve;
  final AnimationType type;

  const AnimatedEntry({
    super.key,
    required this.child,
    this.delay,
    this.duration,
    this.curve,
    this.type = AnimationType.slideAndFade,
  });

  @override
  Widget build(BuildContext context) {
    if (delay != null) {
      return FutureBuilder(
        future: Future.delayed(delay!),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return _buildAnimation();
        },
      );
    }
    return _buildAnimation();
  }

  Widget _buildAnimation() {
    switch (type) {
      case AnimationType.fade:
        return TravelAnimations.fadeIn(
          child: child,
          duration: duration,
          curve: curve,
        );
      case AnimationType.scale:
        return TravelAnimations.scaleIn(
          child: child,
          duration: duration,
          curve: curve,
        );
      case AnimationType.slideFromBottom:
        return TravelAnimations.slideInFromBottom(
          child: child,
          duration: duration,
          curve: curve,
        );
      case AnimationType.bounce:
        return TravelAnimations.bounceIn(
          child: child,
          duration: duration,
        );
      case AnimationType.slideAndFade:
      default:
        return TravelAnimations.slideInFromBottom(
          child: TravelAnimations.fadeIn(
            child: child,
            duration: duration,
            curve: curve,
          ),
          duration: duration,
          curve: curve,
        );
    }
  }
}

/// Tipos de animação disponíveis
enum AnimationType {
  fade,
  scale,
  slideFromBottom,
  bounce,
  slideAndFade,
}

// Made with Bob
