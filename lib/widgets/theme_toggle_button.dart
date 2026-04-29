import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return ListTile(
          leading: Icon(
            _getIcon(themeController.themeMode),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Tema do Aplicativo'),
          subtitle: Text(themeController.getThemeModeName()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(context, themeController),
        );
      },
    );
  }

  IconData _getIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.system:
      default:
        return Icons.brightness_auto;
    }
  }

  void _showThemeDialog(BuildContext context, ThemeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              subtitle: const Text('Sempre usar tema claro'),
              secondary: const Icon(Icons.light_mode),
              value: ThemeMode.light,
              groupValue: controller.themeMode,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Escuro'),
              subtitle: const Text('Sempre usar tema escuro'),
              secondary: const Icon(Icons.dark_mode),
              value: ThemeMode.dark,
              groupValue: controller.themeMode,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Automático'),
              subtitle: const Text('Seguir configuração do sistema'),
              secondary: const Icon(Icons.brightness_auto),
              value: ThemeMode.system,
              groupValue: controller.themeMode,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeToggleIconButton extends StatelessWidget {
  const ThemeToggleIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, child) {
        return IconButton(
          icon: Icon(_getIcon(themeController.themeMode)),
          tooltip: 'Mudar tema',
          onPressed: () => _showThemeDialog(context, themeController),
        );
      },
    );
  }

  IconData _getIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.system:
      default:
        return Icons.brightness_auto;
    }
  }

  void _showThemeDialog(BuildContext context, ThemeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolher Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              subtitle: const Text('Sempre usar tema claro'),
              secondary: const Icon(Icons.light_mode),
              value: ThemeMode.light,
              groupValue: controller.themeMode,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Escuro'),
              subtitle: const Text('Sempre usar tema escuro'),
              secondary: const Icon(Icons.dark_mode),
              value: ThemeMode.dark,
              groupValue: controller.themeMode,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Automático'),
              subtitle: const Text('Seguir configuração do sistema'),
              secondary: const Icon(Icons.brightness_auto),
              value: ThemeMode.system,
              groupValue: controller.themeMode,
              onChanged: (value) {
                if (value != null) {
                  controller.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
