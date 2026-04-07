import 'package:flutter/material.dart';
import 'package:modelia/shared/models/tema_config.dart';

class PreviewTema extends StatefulWidget {
  final TemaConfig config;
  final bool isDarkInicial;

  const PreviewTema({
    super.key,
    required this.config,
    required this.isDarkInicial,
  });

  @override
  State<PreviewTema> createState() => _PreviewTemaState();
}

class _PreviewTemaState extends State<PreviewTema>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isDark = widget.isDarkInicial;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cuando el config cambia desde fuera, reconstruimos
  @override
  void didUpdateWidget(PreviewTema oldWidget) {
    super.didUpdateWidget(oldWidget);
    // No necesitamos hacer nada — build() ya usa widget.config
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final bg = _isDark ? c.darkBg : c.lightBg;
    final surface = _isDark ? c.darkSurface : c.lightSurface;
    final card = _isDark ? c.darkCard : c.lightCard;
    final text = _isDark ? c.textLight : c.textDark;

    return Container(
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── AppBar mock ──────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios_rounded, color: text, size: 14),
                const SizedBox(width: 8),
                Text(
                  _tabController.index == 0
                      ? widget
                            .config
                            .appNombre // ← nombre dinámico
                      : _tabLabel(_tabController.index),
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // Toggle dark/light — funcional
                GestureDetector(
                  onTap: () => setState(() => _isDark = !_isDark),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: text,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: text, size: 18),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TabHome(
                  c: c,
                  bg: bg,
                  surface: surface,
                  card: card,
                  text: text,
                ),
                _TabDetalle(
                  c: c,
                  bg: bg,
                  surface: surface,
                  card: card,
                  text: text,
                ),
                _TabCarrito(
                  c: c,
                  bg: bg,
                  surface: surface,
                  card: card,
                  text: text,
                ),
                _TabPerfil(
                  c: c,
                  bg: bg,
                  surface: surface,
                  card: card,
                  text: text,
                ),
              ],
            ),
          ),

          // ── Bottom nav mock ──────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Inicio',
                    color: _tabController.index == 0
                        ? c.accentColor
                        : text.withValues(alpha: 0.4),
                    onTap: () => setState(() => _tabController.index = 0),
                  ),
                  _NavItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Detalle',
                    color: _tabController.index == 1
                        ? c.accentColor
                        : text.withValues(alpha: 0.4),
                    onTap: () => setState(() => _tabController.index = 1),
                  ),
                  _NavItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Carrito',
                    color: _tabController.index == 2
                        ? c.accentColor
                        : text.withValues(alpha: 0.4),
                    onTap: () => setState(() => _tabController.index = 2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Perfil',
                    color: _tabController.index == 3
                        ? c.accentColor
                        : text.withValues(alpha: 0.4),
                    onTap: () => setState(() => _tabController.index = 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(int index) {
    switch (index) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Detalle producto';
      case 2:
        return 'Carrito';
      case 3:
        return 'Perfil';
      default:
        return 'Modelia';
    }
  }
}

// ── Nav item ───────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tabs mock ──────────────────────────────────────────────

class _TabHome extends StatelessWidget {
  final TemaConfig c;
  final Color bg, surface, card, text;

  const _TabHome({
    required this.c,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  Icons.search_rounded,
                  color: text.withValues(alpha: 0.4),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Buscar...',
                  style: TextStyle(
                    color: text.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(label: 'Todos', bg: c.accentColor, textColor: Colors.white),
              const SizedBox(width: 4),
              _Chip(label: 'Electrónica', bg: surface, textColor: text),
              const SizedBox(width: 4),
              _Chip(label: 'Hogar', bg: surface, textColor: text),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF1D1D1F), Color(0xFF3A3A3C)],
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: c.accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOVEDADES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Descubre los últimos productos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.2,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (i) => _ProductoCard(
                  c: c,
                  card: card,
                  text: text,
                  nombre: ['Auriculares', 'Smartwatch', 'Teclado', 'Ratón'][i],
                  precio: ['89,99', '149,99', '79,99', '49,99'][i],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabDetalle extends StatelessWidget {
  final TemaConfig c;
  final Color bg, surface, card, text;

  const _TabDetalle({
    required this.c,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 70,
              color: surface,
              child: Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: text.withValues(alpha: 0.3),
                  size: 28,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELECTRÓNICA',
                    style: TextStyle(
                      color: c.accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Smartwatch Serie X',
                    style: TextStyle(
                      color: text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '149,99 €',
                        style: TextStyle(
                          color: c.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          '5 en stock',
                          style: TextStyle(color: Colors.green, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: c.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.threed_rotation_rounded,
                            color: c.accentColor,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ver en 3D',
                          style: TextStyle(
                            color: c.accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: c.accentColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Añadir al carrito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCarrito extends StatelessWidget {
  final TemaConfig c;
  final Color bg, surface, card, text;

  const _TabCarrito({
    required this.c,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _ItemCarrito(
            c: c,
            card: card,
            text: text,
            nombre: 'Smartwatch Serie X',
            precio: '149,99 €',
            cantidad: 1,
          ),
          const SizedBox(height: 6),
          _ItemCarrito(
            c: c,
            card: card,
            text: text,
            nombre: 'Auriculares BT Pro',
            precio: '89,99 €',
            cantidad: 2,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3 artículos',
                      style: TextStyle(color: text, fontSize: 10),
                    ),
                    Text(
                      '329,97 €',
                      style: TextStyle(
                        color: c.accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Finalizar compra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPerfil extends StatelessWidget {
  final TemaConfig c;
  final Color bg, surface, card, text;

  const _TabPerfil({
    required this.c,
    required this.bg,
    required this.surface,
    required this.card,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.accentColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Admin',
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: c.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Administrador',
                style: TextStyle(
                  color: c.accentColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _PerfilCampo(
                    icon: Icons.email_outlined,
                    label: 'admin@tienda.com',
                    text: text,
                  ),
                  const SizedBox(height: 4),
                  _PerfilCampo(
                    icon: Icons.person_outline_rounded,
                    label: 'Administrador',
                    text: text,
                  ),
                  const SizedBox(height: 4),
                  _PerfilCampo(
                    icon: Icons.location_on_outlined,
                    label: 'No especificada',
                    text: text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _AccesoRapidoMini(
              icon: Icons.receipt_long_outlined,
              label: 'Mis pedidos',
              surface: surface,
              text: text,
            ),
            const SizedBox(height: 4),
            _AccesoRapidoMini(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Panel admin',
              surface: surface,
              text: c.accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets reutilizables ──────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color bg, textColor;

  const _Chip({required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final TemaConfig c;
  final Color card, text;
  final String nombre, precio;

  const _ProductoCard({
    required this.c,
    required this.card,
    required this.text,
    required this.nombre,
    required this.precio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: text.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: text.withValues(alpha: 0.2),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nombre,
            style: TextStyle(
              color: text,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$precio €',
            style: TextStyle(
              color: c.accentColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCarrito extends StatelessWidget {
  final TemaConfig c;
  final Color card, text;
  final String nombre, precio;
  final int cantidad;

  const _ItemCarrito({
    required this.c,
    required this.card,
    required this.text,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: text.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: text,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  precio,
                  style: TextStyle(
                    color: c.accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'x$cantidad',
            style: TextStyle(color: text.withValues(alpha: 0.5), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _PerfilCampo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color text;

  const _PerfilCampo({
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: text.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: text, fontSize: 9)),
      ],
    );
  }
}

class _AccesoRapidoMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color surface, text;

  const _AccesoRapidoMini({
    required this.icon,
    required this.label,
    required this.surface,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 9,
            color: text.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
