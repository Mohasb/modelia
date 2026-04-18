import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/shared/providers/auth_provider.dart';
import 'package:modelia/shared/providers/carrito_provider.dart';
import 'package:modelia/shared/providers/theme_provider.dart';
import 'package:modelia/core/theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/catalogo')) return 1;
    if (location.startsWith('/mis-pedidos')) return 2;
    if (location.startsWith('/perfil')) return 3;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/catalogo');
      case 2:
        context.go('/mis-pedidos');
      case 3:
        context.go('/perfil');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _locationToIndex(location);
    final totalItems = ref.watch(carritoTotalItemsProvider);
    final authState = ref.watch(authProvider);
    final isDark = ref.watch(themeProvider.notifier).isDark;
    final temaConfig = ref.watch(themeProvider).temaConfig;
    final appNombre = temaConfig.appNombre;
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    if (isWindows) {
      return _WindowsShell(
        appNombre: appNombre,
        selectedIndex: selectedIndex,
        totalItems: totalItems,
        isDark: isDark,
        authState: authState,
        onNavTap: (i) => _onNavTap(context, i),
        onCartTap: () => context.push('/carrito'),
        onDarkToggle: () => ref.read(themeProvider.notifier).toggleDarkMode(),
        onAvatarTap: () =>
            authState.isLogueado ? context.go('/perfil') : context.go('/login'),
        child: child,
      );
    }

    return _AndroidShell(
      appNombre: appNombre,
      selectedIndex: selectedIndex,
      totalItems: totalItems,
      isDark: isDark,
      authState: authState,
      onNavTap: (i) => _onNavTap(context, i),
      onCartTap: () => context.push('/carrito'),
      onDarkToggle: () => ref.read(themeProvider.notifier).toggleDarkMode(),
      onAvatarTap: () =>
          authState.isLogueado ? context.go('/perfil') : context.go('/login'),
      child: child,
    );
  }
}

// ── Android Shell ──────────────────────────────────────────

class _AndroidShell extends StatelessWidget {
  final Widget child;
  final String appNombre;
  final int selectedIndex;
  final int totalItems;
  final bool isDark;
  final dynamic authState;
  final void Function(int) onNavTap;
  final VoidCallback onCartTap;
  final VoidCallback onDarkToggle;
  final VoidCallback onAvatarTap;

  const _AndroidShell({
    required this.child,
    required this.appNombre,
    required this.selectedIndex,
    required this.totalItems,
    required this.isDark,
    required this.authState,
    required this.onNavTap,
    required this.onCartTap,
    required this.onDarkToggle,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ModeliaAppBar(
        appNombre: appNombre,
        isDark: isDark,
        totalItems: totalItems,
        authState: authState,
        onCartTap: onCartTap,
        onDarkToggle: onDarkToggle,
        onAvatarTap: onAvatarTap,
      ),
      body: child,
      bottomNavigationBar: _ModeliaBottomNav(
        selectedIndex: selectedIndex,
        onTap: onNavTap,
      ),
    );
  }
}

// ── Windows Shell ──────────────────────────────────────────

class _WindowsShell extends StatelessWidget {
  final Widget child;
  final String appNombre;
  final int selectedIndex;
  final int totalItems;
  final bool isDark;
  final dynamic authState;
  final void Function(int) onNavTap;
  final VoidCallback onCartTap;
  final VoidCallback onDarkToggle;
  final VoidCallback onAvatarTap;

  const _WindowsShell({
    required this.child,
    required this.appNombre,
    required this.selectedIndex,
    required this.totalItems,
    required this.isDark,
    required this.authState,
    required this.onNavTap,
    required this.onCartTap,
    required this.onDarkToggle,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ModeliaAppBar(
        appNombre: appNombre,
        isDark: isDark,
        totalItems: totalItems,
        authState: authState,
        onCartTap: onCartTap,
        onDarkToggle: onDarkToggle,
        onAvatarTap: onAvatarTap,
        isWindows: true,
      ),
      body: Row(
        children: [
          _ModeliaRail(
            selectedIndex: selectedIndex,
            isDark: isDark,
            onTap: onNavTap,
            onDarkToggle: onDarkToggle,
          ),
          const VerticalDivider(width: 0.5),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── AppBar compartida ──────────────────────────────────────

class _ModeliaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appNombre;
  final bool isDark;
  final int totalItems;
  final dynamic authState;
  final VoidCallback onCartTap;
  final VoidCallback onDarkToggle;
  final VoidCallback onAvatarTap;
  final bool isWindows;

  const _ModeliaAppBar({
    required this.appNombre,
    required this.isDark,
    required this.totalItems,
    required this.authState,
    required this.onCartTap,
    required this.onDarkToggle,
    required this.onAvatarTap,
    this.isWindows = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/icons/icon_header.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            appNombre,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (!isWindows)
          IconButton(
            onPressed: onDarkToggle,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
            ),
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
          ),
        Stack(
          children: [
            IconButton(
              onPressed: onCartTap,
              icon: const Icon(Icons.shopping_bag_outlined, size: 22),
            ),
            if (totalItems > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentGold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      totalItems > 9 ? '9+' : totalItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            margin: const EdgeInsets.only(right: 16, left: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: authState.isLogueado
                  ? Theme.of(context).colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: authState.isLogueado
                  ? Text(
                      (authState.nombre ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom Navigation Bar ──────────────────────────────────

class _ModeliaBottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _ModeliaBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.star_border_outlined),
          activeIcon: Icon(Icons.star),
          label: 'Destacados',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          activeIcon: Icon(Icons.grid_view_rounded),
          label: 'Catálogo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long_rounded),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}

// ── Navigation Rail (Windows) ──────────────────────────────

class _ModeliaRail extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final void Function(int) onTap;
  final VoidCallback onDarkToggle;

  const _ModeliaRail({
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
    required this.onDarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      leading: const SizedBox(height: 8),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDarkToggle,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                  ),
                  tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
                ),
                Text(
                  isDark ? 'Claro' : 'Oscuro',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: Text('Catálogo'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Pedidos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Perfil'),
        ),
      ],
    );
  }
}
