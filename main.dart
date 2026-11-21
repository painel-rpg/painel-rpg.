import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
//  PAINEL RPG — preto, roxo profundo e rosa neon
// ============================================================
const kBg = Color(0xFF05000A);
const kDeep = Color(0xFF1B0638);
const kViolet = Color(0xFFB45CFF);
const kPink = Color(0xFFFF2BD6);
const kText = Color(0xFFF5EBFF);
const kMuted = Color(0xFFA78BCB);
const kWorld = 200.0; // o mapa tem 200 m x 200 m
const kMove = 25.0; // deslocamento por turno
const teamName = ['Rosa', 'Roxo', 'Neutro'];

Color al(Color c, double o) => c.withAlpha((o * 255).round());
Color teamColor(int t) => t == 0 ? kPink : (t == 1 ? kViolet : Colors.white);

// ============================================================
//  DADOS DO SLIDE
// ============================================================
class Skill {
  final String name, desc, status;
  final int mp, min, max, rate, cd, dmg, heal, healLost, bleed, bleedT, shield, shT, statusT, split;
  final int? rate2, dmg2;
  final bool nearFirst, cond, critOnly, revive, clean, sup;
  const Skill(this.name, this.mp, this.min, this.max, this.rate, this.cd, this.desc,
      {this.dmg = 0,
      this.heal = 0,
      this.healLost = 0,
      this.bleed = 0,
      this.bleedT = 0,
      this.shield = 0,
      this.shT = 0,
      this.status = '',
      this.statusT = 0,
      this.rate2,
      this.dmg2,
      this.split = 0,
      this.nearFirst = true,
      this.cond = false,
      this.critOnly = false,
      this.revive = false,
      this.clean = false,
      this.sup = false});
}

class HeroDef {
  final String name, role;
  final int hp, mp, regen, atk, reach;
  final List<Skill> skills;
  const HeroDef(this.name, this.role, this.hp, this.mp, this.regen, this.atk, this.reach, this.skills);
  bool get boss => role.startsWith('Chefe');
  bool get emp => role.startsWith('Imperador');
}

const heroes = <HeroDef>[
  HeroDef('Gladiador', 'Tanque de linha de frente', 1400, 80, 10, 75, 5, [
    Skill('Provocar', 20, 0, 15, 90, 1, 'Paralisa cortando 50% da defesa.',
        status: 'Paralisado (−50% DEF)', statusT: 1),
    Skill('Julgamento da Espada', 30, 10, 50, 85, 2, '145 de dano em alvos vulneráveis ou sangrando.',
        dmg: 145, cond: true),
    Skill('Investida do Touro', 35, 5, 40, 80, 3, '90 de dano neutralizando por 2 turnos.',
        dmg: 90, status: 'Neutralizado', statusT: 2),
    Skill('Muralha de Aço', 25, 0, 10, 90, 2, 'Escudo de 160 HP por 1 turno.',
        shield: 160, shT: 1, sup: true),
    Skill('Golpe Quebra-Guarda', 30, 0, 15, 85, 2, '80 de dano deixando o alvo vulnerável.',
        dmg: 80, status: 'Vulnerável', statusT: 2),
  ]),
  HeroDef('Elfo', 'Ladrão estratégico e coringa', 900, 120, 15, 70, 15, [
    Skill('Magia Proibida', 25, 0, 100, 80, 2,
        'Devolve habilidades arremessáveis com 2× dano (digite o dano devolvido).'),
    Skill('Aperfeiçoamento da Alma', 120, 0, 20, 85, 3, 'Imobiliza 1 turno com 35 de sangramento.',
        bleed: 35, bleedT: 1, status: 'Imobilizado', statusT: 1),
    Skill('Roubo Espiritual', 30, 10, 50, 85, 1, 'Subtrai 1 atributo universal do alvo (10–50 m).',
        status: 'Atributo roubado', statusT: 2),
    Skill('Passo das Sombras', 20, 0, 25, 90, 2, 'Move 25 m sem reação inimiga.',
        status: 'Passo das Sombras', statusT: 1, sup: true),
    Skill('Lâmina Sombria', 30, 0, 30, 85, 2, '75 de dano e 20 de sangramento por 2 turnos.',
        dmg: 75, bleed: 20, bleedT: 2),
  ]),
  HeroDef('Curandeira', 'Suporte e proteção', 950, 140, 18, 45, 20, [
    Skill('Escudo Espiritual', 30, 0, 60, 90, 2, 'Anula investida duplicando o ataque do aliado.',
        status: 'Escudo Espiritual (ATK ×2)', statusT: 1, sup: true),
    Skill('Toque do Anjo', 25, 0, 80, 95, 1, 'Cura 25% da vida perdida (mín. 120).',
        heal: 120, healLost: 25, sup: true),
    Skill('Compaixão Eterna', 60, 0, 50, 100, 3, 'Revive com 50% de HP, sem poderes por 3 turnos.',
        revive: true, sup: true),
    Skill('Luz Purificadora', 25, 0, 60, 95, 2, 'Remove sangramento e cura 90 HP.',
        heal: 90, clean: true, sup: true),
    Skill('Bênção da Aurora', 35, 0, 50, 90, 3, 'Cura 110 HP e +20% de resistência por 2 turnos.',
        heal: 110, status: 'Resist +20%', statusT: 2, sup: true),
  ]),
  HeroDef('Bruxa', 'Controle sombrio e maldição', 850, 150, 18, 95, 30, [
    Skill('Fogo Demoníaco', 35, 0, 100, 85, 2, '220 de dano (≤50 m) ou 110 (≤100 m) + sangramento.',
        dmg: 220, dmg2: 110, rate2: 70, split: 50, nearFirst: true, bleed: 30, bleedT: 1),
    Skill('Bater de Asas Sombrio', 25, 0, 50, 85, 1, '70 de dano imobilizando ou empurrando 50 m.',
        dmg: 70, status: 'Imobilizado', statusT: 1),
    Skill('A Maldição', 55, 0, 50, 75, 4, 'Fogo amigo + 40 de sangramento nos dois (repita no 2º alvo).',
        bleed: 40, bleedT: 2),
    Skill('Correntes Abissais', 30, 0, 70, 85, 2, '65 de dano e imobiliza por 1 turno.',
        dmg: 65, status: 'Imobilizado', statusT: 1),
    Skill('Pacto de Sangue', 35, 0, 80, 85, 2, '85 de dano e 35 de sangramento por 2 turnos.',
        dmg: 85, bleed: 35, bleedT: 2),
  ]),
  HeroDef('Assassino', 'Furtividade e golpe letal', 850, 100, 12, 90, 5, [
    Skill('Investida Atormentadora', 20, 0, 30, 90, 2, '100 de dano + 30 de sangramento por 2 turnos.',
        dmg: 100, bleed: 30, bleedT: 2),
    Skill('O Tormento', 25, 0, 100, 85, 1, '130 de dano: 85% em 50–100 m; 50% abaixo de 50 m.',
        dmg: 130, dmg2: 130, rate2: 50, split: 50, nearFirst: false),
    Skill('A Morte Lenta', 45, 0, 60, 80, 4, '270 de dano crítico ou 45 de sangramento por 3 turnos.',
        dmg: 270, critOnly: true, bleed: 45, bleedT: 3),
    Skill('Corte Silencioso', 20, 0, 15, 90, 2, '85 de dano ignorando bloqueio (0–15 m).', dmg: 85),
    Skill('Bomba de Fumaça', 25, 0, 40, 85, 2, 'Desnorteia o alvo; o assassino recua 20 m.',
        status: 'Desnorteado', statusT: 1),
  ]),
];

const dragao = HeroDef('Dragão Eterno', 'Chefe • contra-ataca com 85 de dano, imobiliza e sangra. Buff (3t): +25% dano e +20 MP/turno',
    1600, 0, 0, 85, 40, []);
const serpente = HeroDef('Serpente Espiritual', 'Chefe • contra-ataca com 60 de dano, imobiliza e sangra. Buff (3t): +30% cura, +30% DEF e −1t recarga',
    1350, 0, 0, 60, 40, []);
const imperador = HeroDef('Imperador', 'Imperador • Sala Imperial, poder 50%', 0, 120, 15, 45, 15, [
  Skill('Decreto Real', 25, 0, 70, 95, 1, 'Concede +25% de ataque a um aliado por 1 turno.',
      status: 'Decreto Real (+25% ATK)', statusT: 1, sup: true),
  Skill('Guarda da Coroa', 35, 0, 50, 95, 2, 'Escudo de 180 HP em si ou num aliado próximo.',
      shield: 180, shT: 2, sup: true),
  Skill('Julgamento Imperial', 50, 0, 30, 85, 3, '90 de dano e empurra inimigos até 30 m.', dmg: 90),
]);

class IslandDef {
  final String name, buff, syn;
  final Color color;
  final Offset pos;
  const IslandDef(this.name, this.buff, this.syn, this.color, this.pos);
}

const islandDefs = <IslandDef>[
  IslandDef('Ilha Infernal', '+25% Dano Direto', 'Bruxa, Assassino e Gladiador', Color(0xFFFF4D4D), Offset(35, 40)),
  IslandDef('Ilha Oceânica', '+30% Cura e Escudos', 'Curandeira e Imperador', Color(0xFF2BB5FF), Offset(100, 30)),
  IslandDef('Ilha do Vento', '−1 Turno de Recarga (mín. 1t)', 'Elfo, Bruxa e Assassino', Color(0xFF2EE6C5), Offset(165, 40)),
  IslandDef('Ilha da Tempestade', '+30% Resistência (teto 70%)', 'Gladiador e linha de frente', Color(0xFF7C7CFF), Offset(35, 160)),
  IslandDef('Ilha da Cobra', '+40% Dano de Sangramento', 'Assassino, Bruxa e Elfo', Color(0xFF3DDC84), Offset(100, 170)),
  IslandDef('Ilha do Encanto', '+1 Turno de Imobilização', 'Gladiador, Bruxa e Elfo', Color(0xFFC45CFF), Offset(165, 160)),
];
const shortNames = ['Infernal', 'Oceânica', 'Vento', 'Tempestade', 'Cobra', 'Encanto'];

// ============================================================
//  ESTADO DO JOGO
// ============================================================
class IslandState {
  int owner = -1, buffT = 0, lock = 0;
}

class Fighter {
  final HeroDef def;
  final int team, maxHp;
  int hp, mp, shield = 0, shT = 0;
  double x, y, ox, oy;
  bool rewarded = false;
  Map<int, int> cd = {};
  Map<String, int> status = {};
  List<List<int>> bleeds = [];
  Fighter(HeroDef d, this.team, double px, double py, {int? hp0})
      : def = d,
        maxHp = hp0 ?? d.hp,
        hp = hp0 ?? d.hp,
        mp = d.mp,
        x = px,
        y = py,
        ox = px,
        oy = py;
  bool get dead => hp <= 0;
  bool get vulnerable => status.containsKey('Vulnerável') || status.containsKey('Desnorteado');
  String get label => def.boss ? def.name : '${def.name} · ${teamName[team]}';
}

class Game extends ChangeNotifier {
  int turn = 1, turnSec = 240, winSec = 30;
  bool running = false, limitMove = true;
  int? sel;
  Fighter? firstDead;
  Timer? _t;
  final List<Fighter> f = [];
  final List<IslandState> isl = List.generate(6, (_) => IslandState());
  final List<String> logs = [];

  Game() {
    reset();
  }

  void ping() => notifyListeners();

  void say(String s) {
    logs.insert(0, 'T$turn · $s');
    if (logs.length > 60) logs.removeLast();
  }

  void reset() {
    _t?.cancel();
    running = false;
    turn = 1;
    turnSec = 240;
    winSec = 30;
    sel = null;
    firstDead = null;
    logs.clear();
    for (final i in isl) {
      i.owner = -1;
      i.buffT = 0;
      i.lock = 0;
    }
    f.clear();
    for (var t = 0; t < 2; t++) {
      for (var i = 0; i < heroes.length; i++) {
        f.add(Fighter(heroes[i], t, 30.0 + 35 * i, t == 0 ? 188.0 : 12.0));
      }
    }
    notifyListeners();
  }

  void toggle() {
    running = !running;
    _t?.cancel();
    if (running) {
      _t = Timer.periodic(const Duration(seconds: 1), (_) {
        if (turnSec > 0) {
          turnSec--;
          if (turnSec == 0) HapticFeedback.vibrate();
        }
        if (winSec > 0) {
          winSec--;
          if (winSec == 0) HapticFeedback.vibrate();
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void nextWindow() {
    winSec = 30;
    if (f.isNotEmpty) {
      final i = sel ?? -1;
      for (var k = 1; k <= f.length; k++) {
        final j = (i + k) % f.length;
        if (!f[j].dead) {
          sel = j;
          break;
        }
      }
    }
    notifyListeners();
  }

  bool has(int team, int i) => team < 2 && isl[i].owner == team && isl[i].buffT > 0;

  int resist(Fighter t) {
    var r = 0;
    if (has(t.team, 3)) r += 30;
    if (t.status.containsKey('Buff Serpente')) r += 30;
    if (t.status.containsKey('Resist +20%')) r += 20;
    return min(r, 70);
  }

  double dist(Fighter a, Fighter b) {
    final dx = a.x - b.x, dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  Skill skillOf(Fighter a, int si) => si < 0
      ? Skill('Ataque Básico', 0, 0, a.def.reach, 90, 0, 'Ataque básico de ${a.def.atk}.', dmg: a.def.atk)
      : a.def.skills[si];

  void moveTo(int i, double px, double py) {
    final a = f[i];
    var x = px.clamp(0.0, kWorld).toDouble();
    var y = py.clamp(0.0, kWorld).toDouble();
    if (limitMove) {
      final lim = a.status.containsKey('Passo das Sombras') ? kMove * 2 : kMove;
      final dx = x - a.ox, dy = y - a.oy;
      final d = sqrt(dx * dx + dy * dy);
      if (d > lim) {
        x = a.ox + dx * lim / d;
        y = a.oy + dy * lim / d;
      }
    }
    a.x = x;
    a.y = y;
    notifyListeners();
  }

  void check(Fighter x) {
    if (x.hp > 0) return;
    x.hp = 0;
    x.shield = 0;
    if (!x.def.boss && !x.def.emp && firstDead == null) {
      firstDead = x;
      say('☠ ${x.label} caiu primeiro — o Imperador pode nascer com ${x.maxHp * 2} HP');
    } else {
      say('☠ ${x.label} caiu');
    }
  }

  void adjHp(Fighter x, int d) {
    x.hp = min(x.maxHp, x.hp + d);
    check(x);
    notifyListeners();
  }

  void adjMp(Fighter x, int d) {
    x.mp = max(0, min(x.def.mp, x.mp + d));
    notifyListeners();
  }

  void spawn(HeroDef d, double x, double y, {int team = 2, int? hp}) {
    f.add(Fighter(d, team, x, y, hp0: hp));
    sel = f.length - 1;
    say('${d.name} entrou na arena');
    notifyListeners();
  }

  void summonEmperor() {
    final d = firstDead;
    if (d == null || f.any((x) => x.def.emp)) return;
    spawn(imperador, 100, 100, team: d.team, hp: d.maxHp * 2);
    winSec = 30;
  }

  void bossBuff(Fighter boss, int team) {
    final key = boss.def.name.startsWith('Dragão') ? 'Buff Dragão' : 'Buff Serpente';
    for (final x in f) {
      if (x.team == team && !x.dead && !x.def.boss) x.status[key] = 3;
    }
    boss.rewarded = true;
    say('Time ${teamName[team]} recebeu $key por 3 turnos');
    notifyListeners();
  }

  String? conquer(int i, int team) {
    final s = isl[i];
    if (turn < 3) return 'As ilhas só liberam após 2 turnos inteiros (a partir do turno 3).';
    if (s.lock > 0) return 'Ilha em reconquista: aguarde 1 turno.';
    s.owner = team;
    s.buffT = 2;
    say('Time ${teamName[team]} conquistou a ${islandDefs[i].name}');
    notifyListeners();
    return null;
  }

  void loseIsland(int i) {
    final s = isl[i];
    if (s.owner < 0) return;
    say('${islandDefs[i].name} perdida');
    s.owner = -1;
    s.buffT = 0;
    s.lock = 1;
    notifyListeners();
  }

  void nextTurn() {
    for (final x in f) {
      if (x.dead) continue;
      final keep = <List<int>>[];
      for (final b in x.bleeds) {
        x.hp -= b[0];
        b[1]--;
        if (b[1] > 0) keep.add(b);
      }
      x.bleeds = keep;
      x.cd.updateAll((k, v) => v - 1);
      x.cd.removeWhere((k, v) => v <= 0);
      final extra = x.status.containsKey('Buff Dragão') ? 20 : 0;
      x.mp = min(x.def.mp, x.mp + x.def.regen + extra);
      x.status.updateAll((k, v) => v - 1);
      x.status.removeWhere((k, v) => v <= 0);
      if (x.shT > 0) {
        x.shT--;
        if (x.shT == 0) x.shield = 0;
      }
      x.ox = x.x;
      x.oy = x.y;
      check(x);
    }
    for (final s in isl) {
      if (s.owner >= 0) {
        s.buffT--;
        if (s.buffT <= 0) {
          s.owner = -1;
          s.lock = 1;
        }
      } else if (s.lock > 0) {
        s.lock--;
      }
    }
    turn++;
    turnSec = 240;
    winSec = 30;
    say('Virada de turno: sangramentos aplicados, recargas reduzidas, mana regenerada');
    notifyListeners();
  }

  /// Executa uma habilidade já com a rolagem decidida. Retorna o texto do resultado.
  String use(Fighter a, int si, Fighter t, int rate, int roll, int dmgIn) {
    final s = skillOf(a, si);
    a.mp -= s.mp;
    final crit = roll <= 5;
    final ok = crit || roll <= rate;
    if (s.cd > 0 && si >= 0) {
      var c = s.cd;
      if (has(a.team, 2)) c--;
      if (a.status.containsKey('Buff Serpente')) c--;
      a.cd[si] = max(1, c);
    }
    final head = '${a.label} → ${s.name} em ${t.label} (d100 $roll / $rate%)';
    if (!ok) {
      final m = '$head: FALHOU';
      say(m);
      notifyListeners();
      return m;
    }
    final parts = <String>[];
    var mult = 1.0;
    if (crit) mult *= 1.2;
    if (has(a.team, 0)) mult *= 1.25;
    if (a.status.containsKey('Buff Dragão')) mult *= 1.25;
    if (a.status.containsKey('Decreto Real (+25% ATK)')) mult *= 1.25;
    var hm = 1.0;
    if (crit) hm *= 1.2;
    if (has(a.team, 1)) hm *= 1.3;
    if (a.status.containsKey('Buff Serpente')) hm *= 1.3;

    if (s.revive) {
      t.hp = t.maxHp ~/ 2;
      t.bleeds = [];
      t.status.clear();
      t.status['Sem poderes'] = 3;
      parts.add('reviveu com ${t.hp} HP');
    }
    var dmg = dmgIn;
    if (s.critOnly && !crit) dmg = 0;
    if (s.cond && !(t.vulnerable || t.bleeds.isNotEmpty)) {
      dmg = 0;
      parts.add('alvo não está vulnerável/sangrando: sem dano');
    }
    if (dmg > 0) {
      dmg = (dmg * mult).round();
      dmg = (dmg * (100 - resist(t)) / 100).round();
      final ab = min(t.shield, dmg);
      t.shield -= ab;
      dmg -= ab;
      t.hp -= dmg;
      parts.add('$dmg de dano${ab > 0 ? ' (escudo absorveu $ab)' : ''}');
    }
    var h = s.heal;
    if (s.healLost > 0) h = max(h, ((t.maxHp - t.hp) * s.healLost / 100).round());
    if (h > 0) {
      h = (h * hm).round();
      t.hp = min(t.maxHp, t.hp + h);
      parts.add('curou $h HP');
    }
    if (s.shield > 0) {
      var sh = s.shield.toDouble();
      if (has(a.team, 1)) sh *= 1.3;
      t.shield += sh.round();
      t.shT = max(t.shT, s.shT);
      parts.add('escudo +${sh.round()}');
    }
    var bl = s.bleed;
    if (s.critOnly && crit) bl = 0;
    if (bl > 0) {
      var d = bl;
      if (has(a.team, 4)) d = (d * 1.4).round();
      if (t.bleeds.length >= 2) t.bleeds.removeAt(0); // máx. 2 pilhas
      t.bleeds.add([d, s.bleedT]);
      parts.add('sangramento $d × ${s.bleedT}t');
    }
    if (s.clean) {
      t.bleeds = [];
      parts.add('sangramento removido');
    }
    if (s.status.isNotEmpty) {
      var n = s.statusT;
      if (s.status.startsWith('Imobiliz') && has(a.team, 5)) n++;
      t.status[s.status] = n;
      parts.add('${s.status} ${n}t');
    }
    check(t);
    final m = '$head: ${parts.isEmpty ? 'efeito aplicado' : parts.join(', ')}${crit ? ' ★CRÍTICO' : ''}';
    say(m);
    notifyListeners();
    return m;
  }
}

final game = Game();

// ============================================================
//  APP
// ============================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PainelApp());
}

class PainelApp extends StatelessWidget {
  const PainelApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Painel RPG',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(
              primary: kPink, onPrimary: Colors.black, secondary: kViolet, surface: kDeep, onSurface: kText),
          bottomSheetTheme: const BottomSheetThemeData(backgroundColor: kDeep),
        ),
        home: const Home(),
      );
}

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), backgroundColor: kDeep));

void confirm(BuildContext c, String title, String body, VoidCallback ok) {
  showDialog<bool>(
    context: c,
    builder: (d) => AlertDialog(
      backgroundColor: kDeep,
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Confirmar')),
      ],
    ),
  ).then((v) {
    if (v == true) ok();
  });
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    const pages = [MapTab(), CombatTab(), HeroesTab(), RulesTab()];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const TimerBar(),
          Expanded(child: IndexedStack(index: tab, children: pages)),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        backgroundColor: kDeep,
        indicatorColor: al(kPink, .3),
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Combate'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Heróis'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Regras'),
        ],
      ),
    );
  }
}

// ---------------- Cronômetros ----------------
class TimerBar extends StatelessWidget {
  const TimerBar({super.key});
  String _f(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: game,
        builder: (c, _) => Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(color: kDeep, border: Border(bottom: BorderSide(color: al(kPink, .6)))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TURNO ${game.turn}',
                  style: const TextStyle(color: kPink, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12)),
              Text(_f(game.turnSec),
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: game.turnSec == 0 ? Colors.redAccent : kText)),
            ]),
            const SizedBox(width: 18),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('JANELA', style: TextStyle(color: kMuted, fontSize: 12, letterSpacing: 1.5)),
              Text(_f(game.winSec),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: game.winSec == 0 ? Colors.redAccent : (game.winSec <= 10 ? Colors.amber : kViolet))),
            ]),
            const Spacer(),
            IconButton(
                tooltip: 'Iniciar/pausar',
                onPressed: game.toggle,
                icon: Icon(game.running ? Icons.pause_circle : Icons.play_circle),
                color: kPink,
                iconSize: 36),
            IconButton(
                tooltip: 'Próximo personagem (30 s)',
                onPressed: game.nextWindow,
                icon: const Icon(Icons.skip_next),
                color: kViolet),
            IconButton(
                tooltip: 'Virar turno',
                onPressed: () => confirm(c, 'Virar o turno?',
                    'Aplica sangramentos, reduz recargas e regenera a mana de todos.', game.nextTurn),
                icon: const Icon(Icons.flag),
                color: kText),
          ]),
        ),
      );
}

// ---------------- Mapa 2D ----------------
class MapTab extends StatelessWidget {
  const MapTab({super.key});
  @override
  Widget build(BuildContext context) => const Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(8, 8, 8, 0), child: MapBoard()),
        Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(12), child: SelPanel())),
      ]);
}

class MapBoard extends StatefulWidget {
  const MapBoard({super.key});
  @override
  State<MapBoard> createState() => _MapBoardState();
}

class _MapBoardState extends State<MapBoard> {
  int? _drag;
  int? _hit(Offset p, double k) {
    for (var i = game.f.length - 1; i >= 0; i--) {
      final o = Offset(game.f[i].x * k, game.f[i].y * k);
      if ((o - p).distance <= 20) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final w = box.maxWidth;
        final k = w / kWorld;
        return AnimatedBuilder(
          animation: game,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: w,
              height: w,
              child: GestureDetector(
                onPanStart: (d) {
                  final i = _hit(d.localPosition, k);
                  _drag = i;
                  if (i != null) {
                    game.sel = i;
                    game.ping();
                  }
                },
                onPanUpdate: (d) {
                  final i = _drag;
                  if (i != null && i < game.f.length) {
                    game.moveTo(i, d.localPosition.dx / k, d.localPosition.dy / k);
                  }
                },
                onPanEnd: (_) => _drag = null,
                onPanCancel: () => _drag = null,
                onTapUp: (d) {
                  final i = _hit(d.localPosition, k);
                  if (i != null) {
                    game.sel = i;
                    game.ping();
                    return;
                  }
                  final m = Offset(d.localPosition.dx / k, d.localPosition.dy / k);
                  for (var j = 0; j < 6; j++) {
                    if ((islandDefs[j].pos - m).distance <= 15) {
                      openIsland(context, j);
                      return;
                    }
                  }
                },
                child: CustomPaint(painter: BoardPainter(), size: Size(w, w)),
              ),
            ),
          ),
        );
      });
}

void txt(Canvas c, String t, Offset p, {double size = 10, Color color = kText, bool bold = false}) {
  final tp = TextPainter(
    text: TextSpan(
        text: t,
        style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
}

class BoardPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / kWorld;
    final r = Offset.zero & s;
    c.drawRect(
        r,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFF2B0A57), Color(0xFF06000D)], radius: 0.85)
              .createShader(r));
    final gp = Paint()..strokeWidth = 1;
    for (var m = 0; m <= 200; m += 10) {
      gp.color = al(kViolet, m % 50 == 0 ? .30 : .08);
      c.drawLine(Offset(m * k, 0), Offset(m * k, s.height), gp);
      c.drawLine(Offset(0, m * k), Offset(s.width, m * k), gp);
      if (m % 50 == 0 && m > 0 && m < 200) txt(c, '${m}m', Offset(m * k + 12, 8), size: 8, color: al(kMuted, .8));
    }
    // ilhas
    for (var i = 0; i < 6; i++) {
      final d = islandDefs[i];
      final st = game.isl[i];
      final p = d.pos * k;
      c.drawCircle(p, 15 * k, Paint()..color = al(d.color, st.owner >= 0 ? .35 : .15));
      c.drawCircle(
          p,
          15 * k,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = st.owner >= 0 ? 3 : 1.5
            ..color = st.owner >= 0 ? teamColor(st.owner) : al(d.color, .8));
      txt(c, '${i + 1}', p - const Offset(0, 6), size: 15, color: d.color, bold: true);
      txt(c, st.owner >= 0 ? '${st.buffT}t' : shortNames[i], p + const Offset(0, 9), size: 8.5);
    }
    // anéis de distância e limite de deslocamento do selecionado
    final si = game.sel;
    if (si != null && si < game.f.length) {
      final a = game.f[si];
      final p = Offset(a.x * k, a.y * k);
      final rings = [
        [10, 0xFFFF4D6D],
        [50, 0xFFFFC857],
        [100, 0xFF4DA3FF],
        [150, 0xFFB8C0D0]
      ];
      for (final g in rings) {
        c.drawCircle(
            p,
            g[0] * k,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..color = al(Color(g[1]), .75));
        txt(c, '${g[0]}m', p + Offset(0, -g[0] * k), size: 8, color: Color(g[1]), bold: true);
      }
      final lim = a.status.containsKey('Passo das Sombras') ? kMove * 2 : kMove;
      if (game.limitMove) {
        c.drawCircle(
            Offset(a.ox * k, a.oy * k),
            lim * k,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = al(kPink, .55));
      }
    }
    // personagens
    for (var i = 0; i < game.f.length; i++) {
      final x = game.f[i];
      final p = Offset(x.x * k, x.y * k);
      final col = x.dead ? Colors.grey : teamColor(x.team);
      c.drawCircle(p, 13, Paint()..color = al(Colors.black, .85));
      c.drawCircle(
          p,
          13,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = al(col, .3));
      if (!x.dead) {
        final ratio = min(1.0, max(0.0, x.hp / x.maxHp));
        c.drawArc(
            Rect.fromCircle(center: p, radius: 13),
            -pi / 2,
            2 * pi * ratio,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = col);
      }
      txt(c, x.dead ? '✕' : x.def.name[0], p, size: 13, color: col, bold: true);
      if (i == si) {
        c.drawCircle(
            p,
            18,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

String cat(double d) =>
    d <= 10 ? 'Corpo a corpo' : (d <= 50 ? 'Curto' : (d <= 100 ? 'Médio' : (d <= 150 ? 'Extremo' : 'Fora')));
Color catColor(double d) => d <= 10
    ? const Color(0xFFFF4D6D)
    : (d <= 50 ? const Color(0xFFFFC857) : (d <= 100 ? const Color(0xFF4DA3FF) : const Color(0xFFB8C0D0)));

Widget bar(String l, int v, int m, Color col) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 30, child: Text(l, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(
            child: LinearProgressIndicator(
                value: m == 0 ? 0.0 : min(1.0, max(0.0, v / m)),
                color: col,
                backgroundColor: al(col, .2),
                minHeight: 8,
                borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 8),
        Text('$v/$m', style: const TextStyle(fontSize: 12)),
      ]),
    );

Widget chip(String t, Color col) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: al(col, .18), borderRadius: BorderRadius.circular(20), border: Border.all(color: al(col, .6))),
      child: Text(t, style: const TextStyle(fontSize: 12, color: kText)),
    );

class SelPanel extends StatelessWidget {
  const SelPanel({super.key});
  Widget _ab(BuildContext c, Fighter a, int i) {
    final s = game.skillOf(a, i);
    final cd = i < 0 ? 0 : (a.cd[i] ?? 0);
    final can = !a.dead && cd == 0 && a.mp >= s.mp;
    final tag = cd > 0 ? 'CD $cd' : '${s.mp} MP';
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
          foregroundColor: kPink, side: BorderSide(color: can ? kPink : al(kMuted, .4))),
      onPressed: can ? () => openAction(c, a, i) : null,
      child: Text(i < 0 ? 'Básico · ${a.def.atk}' : '${i + 1}. ${s.name} · $tag'),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: game,
        builder: (c, _) {
          final i = game.sel;
          if (i == null || i >= game.f.length) {
            return const Text(
                'Toque num personagem para selecioná-lo e arraste para mover (até 25 m por turno). Toque numa ilha para conquistá-la.',
                style: TextStyle(color: kMuted));
          }
          final a = game.f[i];
          final others = game.f.where((x) => x != a && !x.dead).toList()
            ..sort((p, q) => game.dist(a, p).compareTo(game.dist(a, q)));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.label, style: TextStyle(color: teamColor(a.team), fontSize: 18, fontWeight: FontWeight.w800)),
            Text(a.def.role, style: const TextStyle(color: kMuted, fontSize: 12)),
            bar('HP', a.hp, a.maxHp, kPink),
            if (a.def.mp > 0) bar('MP', a.mp, a.def.mp, kViolet),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (var n = -1; n < a.def.skills.length; n++) _ab(c, a, n)]),
            const SizedBox(height: 12),
            const Text('Distâncias', style: TextStyle(fontWeight: FontWeight.bold, color: kViolet)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final x in others)
                chip('${x.label}: ${game.dist(a, x).round()} m · ${cat(game.dist(a, x))}', catColor(game.dist(a, x)))
            ]),
          ]);
        },
      );
}

// ---------------- Ações (habilidades) ----------------
void openAction(BuildContext ctx, Fighter a, int si) {
  final s = game.skillOf(a, si);
  final cands = game.f.where((x) => s.revive ? x.dead : !x.dead).toList();
  if (cands.isEmpty) {
    snack(ctx, 'Nenhum alvo disponível.');
    return;
  }
  Fighter pick() {
    if (s.sup) {
      if (cands.contains(a)) return a;
      return cands.firstWhere((x) => x.team == a.team, orElse: () => cands.first);
    }
    return cands.firstWhere((x) => x.team != a.team, orElse: () => cands.first);
  }

  Fighter t = pick();
  final dc = TextEditingController();
  final rc = TextEditingController();
  var ext = false;
  var vul = false;
  bool primary(double d) => s.split == 0 || (s.nearFirst ? d <= s.split : d >= s.split);
  void sync() {
    final p = primary(game.dist(a, t));
    dc.text = '${p ? s.dmg : (s.dmg2 ?? s.dmg)}';
    vul = t.vulnerable;
  }

  sync();
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: kDeep,
    builder: (bc) => StatefulBuilder(builder: (bc, setS) {
      final d = game.dist(a, t);
      final base = primary(d) ? s.rate : (s.rate2 ?? s.rate);
      final rate = min(100, max(1, base - (ext ? 15 : 0) + (vul ? 15 : 0)));
      final inRange = d >= s.min && d <= s.max;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(bc).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${a.label} · ${s.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPink)),
            Text(s.desc, style: const TextStyle(color: kMuted)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Alvo: '),
              Expanded(
                child: DropdownButton<Fighter>(
                  isExpanded: true,
                  value: t,
                  dropdownColor: kDeep,
                  items: [for (final x in cands) DropdownMenuItem(value: x, child: Text(x.label))],
                  onChanged: (v) {
                    if (v == null) return;
                    setS(() {
                      t = v;
                      sync();
                    });
                  },
                ),
              ),
            ]),
            Text('Distância: ${d.toStringAsFixed(1)} m · alcance ${s.min}–${s.max} m ${inRange ? '✓' : '✗ fora do alcance'}',
                style: TextStyle(color: inRange ? kText : Colors.redAccent)),
            SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Distância estendida (−15%)'),
                value: ext,
                onChanged: (v) => setS(() => ext = v)),
            SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Alvo vulnerável/desnorteado (+15%)'),
                value: vul,
                onChanged: (v) => setS(() => vul = v)),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: dc,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Dano base'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: rc,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Dado físico (vazio = rolar)'))),
            ]),
            const SizedBox(height: 10),
            Text('Taxa de sucesso: $rate% · custo ${s.mp} MP · 01–05 = crítico (+20%)',
                style: const TextStyle(color: kPink, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (a.mp < s.mp) {
                    snack(ctx, 'MP insuficiente.');
                    return;
                  }
                  final roll = min(100, max(1, int.tryParse(rc.text) ?? (Random().nextInt(100) + 1)));
                  final dm = int.tryParse(dc.text) ?? 0;
                  Navigator.pop(bc);
                  snack(ctx, game.use(a, si, t, rate, roll, dm));
                },
                child: const Text('Executar'),
              ),
            ),
          ]),
        ),
      );
    }),
  );
}

// ---------------- Ilhas ----------------
void openIsland(BuildContext c, int i) {
  final d = islandDefs[i];
  final s = game.isl[i];
  showModalBottomSheet(
    context: c,
    backgroundColor: kDeep,
    builder: (bc) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${i + 1}. ${d.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: d.color)),
        Text('Buff: ${d.buff}'),
        Text('Sinergias: ${d.syn}', style: const TextStyle(color: kMuted)),
        const SizedBox(height: 6),
        Text(s.owner >= 0
            ? 'Controlada pelo Time ${teamName[s.owner]} · ${s.buffT} turno(s) de buff'
            : (s.lock > 0 ? 'Em reconquista (${s.lock} turno)' : (game.turn < 3 ? 'Bloqueada até o turno 3' : 'Livre'))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final t in [0, 1])
            FilledButton(
              onPressed: () {
                final err = game.conquer(i, t);
                Navigator.pop(bc);
                if (err != null) snack(c, err);
              },
              child: Text('Conquistar · ${teamName[t]}'),
            ),
        ]),
        TextButton(
          onPressed: s.owner >= 0
              ? () {
                  game.loseIsland(i);
                  Navigator.pop(bc);
                }
              : null,
          child: const Text('Ilha perdida (herói recuou)'),
        ),
      ]),
    ),
  );
}

// ---------------- Combate ----------------
class CombatTab extends StatelessWidget {
  const CombatTab({super.key});

  Widget _mini(String t, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: kText,
              side: BorderSide(color: al(kViolet, .6))),
          onPressed: f,
          child: Text(t),
        ),
      );

  void _add(BuildContext c) {
    showDialog<void>(
      context: c,
      builder: (d) => SimpleDialog(
        backgroundColor: kDeep,
        title: const Text('Adicionar herói'),
        children: [
          for (final h in heroes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: Text(h.name)),
                for (var t = 0; t < 2; t++)
                  TextButton(
                    onPressed: () {
                      game.spawn(h, 100.0, t == 0 ? 150.0 : 50.0, team: t);
                      Navigator.pop(d);
                    },
                    child: Text(teamName[t]),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext c, int i) {
    final x = game.f[i];
    final col = x.dead ? kMuted : teamColor(x.team);
    return GestureDetector(
      onTap: () {
        game.sel = i;
        game.ping();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kDeep,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: game.sel == i ? kPink : al(col, .5), width: game.sel == i ? 2 : 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(x.label, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 16))),
            IconButton(
                icon: const Icon(Icons.delete_outline),
                color: kMuted,
                onPressed: () {
                  game.f.removeAt(i);
                  game.sel = null;
                  game.ping();
                }),
          ]),
          bar('HP', x.hp, x.maxHp, kPink),
          Row(children: [
            for (final d in [-50, -10, 10, 50]) _mini('${d > 0 ? '+' : ''}$d', () => game.adjHp(x, d)),
          ]),
          if (x.def.mp > 0) bar('MP', x.mp, x.def.mp, kViolet),
          if (x.def.mp > 0)
            Row(children: [
              for (final d in [-10, 10]) _mini('${d > 0 ? '+' : ''}$d', () => game.adjMp(x, d)),
            ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final b in x.bleeds) chip('🩸 ${b[0]} × ${b[1]}t', Colors.redAccent),
            for (final e in x.status.entries) chip('${e.key} ${e.value}t', kViolet),
            if (x.shield > 0) chip('🛡 ${x.shield}', Colors.cyanAccent),
            for (final e in x.cd.entries) chip('${x.def.skills[e.key].name}: CD ${e.value}', kMuted),
          ]),
          if (x.dead && x.def.boss && !x.rewarded)
            Row(children: [
              const Text('Golpe final: '),
              TextButton(onPressed: () => game.bossBuff(x, 0), child: const Text('Time Rosa')),
              TextButton(onPressed: () => game.bossBuff(x, 1), child: const Text('Time Roxo')),
            ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: game,
        builder: (c, _) => ListView(padding: const EdgeInsets.all(12), children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(onPressed: () => _add(c), icon: const Icon(Icons.person_add), label: const Text('Herói')),
            FilledButton.tonalIcon(
                onPressed: game.turn >= 5 && !game.f.any((x) => x.def.name == dragao.name)
                    ? () => game.spawn(dragao, 70, 100)
                    : null,
                icon: const Icon(Icons.whatshot),
                label: const Text('Dragão (T5)')),
            FilledButton.tonalIcon(
                onPressed: game.turn >= 5 && !game.f.any((x) => x.def.name == serpente.name)
                    ? () => game.spawn(serpente, 130, 100)
                    : null,
                icon: const Icon(Icons.waves),
                label: const Text('Serpente (T5)')),
            FilledButton.tonalIcon(
                onPressed: game.firstDead != null && !game.f.any((x) => x.def.emp) ? game.summonEmperor : null,
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Imperador')),
            OutlinedButton.icon(
                onPressed: () => confirm(c, 'Reiniciar partida?', 'Tudo volta ao estado inicial.', game.reset),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar')),
          ]),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Limitar deslocamento a 25 m por turno'),
              value: game.limitMove,
              onChanged: (v) {
                game.limitMove = v;
                game.ping();
              }),
          for (var i = 0; i < game.f.length; i++) _card(c, i),
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('Registro'),
            children: [
              for (final l in game.logs.take(25)) ListTile(dense: true, title: Text(l, style: const TextStyle(fontSize: 12))),
            ],
          ),
        ]),
      );
}

// ---------------- Heróis ----------------
class HeroesTab extends StatelessWidget {
  const HeroesTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(children: [
        for (final h in [...heroes, imperador, dragao, serpente])
          ExpansionTile(
            title: Text(h.name, style: const TextStyle(color: kPink, fontWeight: FontWeight.w800)),
            subtitle: Text(h.role, style: const TextStyle(fontSize: 12)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${h.hp == 0 && h.emp ? 'HP = 2× do 1º aliado morto' : 'HP ${h.hp}'}'
                  '${h.mp > 0 ? ' · MP ${h.mp} (+${h.regen}/turno)' : ''}'
                  ' · Básico ${h.atk} (0–${h.reach} m)',
                  style: const TextStyle(color: kViolet)),
              for (var i = 0; i < h.skills.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${i + 1}. ${h.skills[i].name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        '${h.skills[i].mp} MP · ${h.skills[i].min}–${h.skills[i].max} m · '
                        '${h.skills[i].rate}%${h.skills[i].rate2 != null ? '/${h.skills[i].rate2}%' : ''} · '
                        'recarga ${h.skills[i].cd}t',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                    Text(h.skills[i].desc),
                  ]),
                ),
            ],
          ),
      ]);
}

// ---------------- Regras e ilhas ----------------
class RulesTab extends StatelessWidget {
  const RulesTab({super.key});
  static const rules = <List<String>>[
    ['1. Período do turno', 'Período máximo do turno: 4 min (240 s) para concluir a rodada inteira.\nJanela por personagem: 30 s para decidir e agir na sua vez.\nVirada de turno: ao fechar os 4 minutos, aplica sangramentos, reduz recargas e regenera a mana de todos.'],
    ['2. Distância (0 a 150 m)', '0–10 m Corpo a corpo: golpes próximos e provocação.\n10–50 m Curto alcance: investidas, roubos e fogo intenso.\n50–100 m Médio alcance: magias de longa distância e avanços.\n100–150 m Extremo: apenas deslocamento ou suporte real.\nDeslocamento de mesa: cada personagem pode caminhar até 25 m por turno dentro da sua janela de 30 s.'],
    ['3. Taxa de sucesso (d100)', 'Faixa ideal da habilidade: 85% a 95%.\nDistância estendida: 65% a 75% (penalidade de −15% ao atirar perto do limite).\nAlvo desnorteado/vulnerável: +15% de bônus.\nRegra de mesa: rola 1d100 (ou 1d20 × 5). Resultado igual ou menor que a taxa = sucesso; 01–05 = crítico (+20% de efeito).'],
    ['4. Sangramento por turno', 'Quando aplica: na virada dos 4 minutos, causa dano no fim do turno e gasta 1 turno de duração.\nIlha da Cobra: +40% de dano de sangramento; máximo de 2 pilhas ativas.\nSem nova rolagem: dano direto na vida após o acerto inicial.\nExemplo: 30 de sangramento por 2 turnos = 30 no 1º + 30 no 2º (60 total; 84 com a Ilha da Cobra).'],
    ['5. Conquista das ilhas', 'Abertura: as ilhas liberam após 2 turnos inteiros.\nPara conquistar: 1 herói explora dentro da ilha por 1 turno.\nCom os buffs: o time usa os bônus da ilha por 2 turnos.\nReconquista: 1 turno de intervalo antes de conquistar novamente.\nRegra de perda: a ilha é perdida se o herói recuar por ataque adversário ou ao terminar os 2 turnos de buff.'],
    ['6. Chefes neutros (nascem após o 4º turno)', 'Dragão Eterno — 1.600 HP, alcance 0–40 m, turno 5. Contra-ataca com 85 de dano, imobiliza e sangra. Buff (3t): +25% dano e +20 MP/turno.\nA Serpente Espiritual — 1.350 HP, alcance 0–40 m, turno 5. Contra-ataca com 60 de dano, imobiliza e sangra. Buff (3t): +30% cura, +30% DEF e −1t recarga.\nRegra de combate: punem atacantes isolados; o time que der o golpe final recebe o buff por 3 turnos.'],
    ['7. Sistema do Imperador — Sala Imperial', 'HP = 2× o do 1º aliado morto; 120 MP (+15/turno); básico 45 (0–15 m), poder 50%.\n1. Decreto Real — 25 MP, 0–70 m, 95%: +25% de ataque a um aliado por 1 turno.\n2. Guarda da Coroa — 35 MP, 0–50 m, 95%: escudo de 180 HP em si ou num aliado próximo.\n3. Julgamento Imperial — 50 MP, 0–30 m, 85%: 90 de dano e empurra inimigos até 30 m.\nCondição de vitória: entra na vaga do 1º morto com janela de 30 s; a partida acaba apenas quando o Imperador morre.'],
  ];

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(8), children: [
        const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Ilhas elementais (toque para gerenciar)',
                style: TextStyle(color: kPink, fontWeight: FontWeight.w800, fontSize: 16))),
        AnimatedBuilder(
          animation: game,
          builder: (c, _) => Column(children: [
            for (var i = 0; i < 6; i++)
              ListTile(
                dense: true,
                onTap: () => openIsland(c, i),
                leading: CircleAvatar(radius: 6, backgroundColor: islandDefs[i].color),
                title: Text('${i + 1}. ${islandDefs[i].name} — ${islandDefs[i].buff}',
                    style: TextStyle(color: islandDefs[i].color, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${islandDefs[i].syn} · ${game.isl[i].owner >= 0 ? 'Time ${teamName[game.isl[i].owner]} (${game.isl[i].buffT}t)' : (game.isl[i].lock > 0 ? 'reconquista' : 'livre')}'),
              ),
          ]),
        ),
        for (final r in rules)
          ExpansionTile(
            title: Text(r[0], style: const TextStyle(fontWeight: FontWeight.bold)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(r[1], style: const TextStyle(height: 1.4))],
          ),
      ]);
}
