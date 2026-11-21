import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
//  PAINEL RPG — preto, roxo profundo e rosa neon (Mapa 3D)
// ============================================================
const kBg = Color(0xFF05000A);
const kDeep = Color(0xFF1B0638);
const kPanel = Color(0xFF120326);
const kViolet = Color(0xFFB45CFF);
const kPink = Color(0xFFFF2BD6);
const kCyan = Color(0xFF38F2FF);
const kText = Color(0xFFF5EBFF);
const kMuted = Color(0xFFA78BCB);
const kWorld = 200.0; // 200 m x 200 m
const kMove = 25.0; // deslocamento por turno
const teamName = ['Rosa', 'Roxo', 'Neutro'];

Color al(Color c, double o) => c.withAlpha((o.clamp(0.0, 1.0) * 255).round());
Color teamColor(int t) => t == 0 ? kPink : (t == 1 ? kViolet : kCyan);

// ============================================================
//  DADOS DO RPG
// ============================================================
class Skill {
  final String name, desc, status;
  final int mp, min, max, rate, cd, dmg, heal, healLost, bleed, bleedT, shield, shT, statusT, split;
  final int? rate2, dmg2;
  final bool nearFirst, cond, critOnly, revive, clean, sup;
  const Skill(
    this.name,
    this.mp,
    this.min,
    this.max,
    this.rate,
    this.cd,
    this.desc, {
    this.dmg = 0,
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
    this.sup = false,
  });
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

const dragao = HeroDef(
  'Dragão Eterno',
  'Chefe • contra-ataca com 85 de dano, imobiliza e sangra. Buff (3t): +25% dano e +20 MP/turno',
  1600,
  0,
  0,
  85,
  40,
  [],
);
const serpente = HeroDef(
  'Serpente Espiritual',
  'Chefe • contra-ataca com 60 de dano, imobiliza e sangra. Buff (3t): +30% cura, +30% DEF e −1t recarga',
  1350,
  0,
  0,
  60,
  40,
  [],
);
const imperador = HeroDef(
  'Imperador',
  'Imperador • Sala Imperial, poder 50%',
  0,
  120,
  15,
  45,
  15,
  [
    Skill('Decreto Real', 25, 0, 70, 95, 1, 'Concede +25% de ataque a um aliado por 1 turno.',
        status: 'Decreto Real (+25% ATK)', statusT: 1, sup: true),
    Skill('Guarda da Coroa', 35, 0, 50, 95, 2, 'Escudo de 180 HP em si ou num aliado próximo.',
        shield: 180, shT: 2, sup: true),
    Skill('Julgamento Imperial', 50, 0, 30, 85, 3, '90 de dano e empurra inimigos até 30 m.', dmg: 90),
  ],
);

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
  int? previewSkill; // habilidade selecionada para mostrar alcance no mapa 3D
  Fighter? firstDead;
  Timer? _t;
  final List<Fighter> f = [];
  final List<IslandState> isl = List.generate(6, (_) => IslandState());
  final List<String> logs = [];

  Game() {
    reset();
  }

  void ping() => notifyListeners();

  void selectFighter(int? index) {
    sel = index;
    previewSkill = null;
    notifyListeners();
  }

  void toggleSkillPreview(int skillIndex) {
    previewSkill = previewSkill == skillIndex ? null : skillIndex;
    notifyListeners();
  }

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
    previewSkill = null;
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
        f.add(Fighter(heroes[i], t, 30.0 + 35 * i, t == 0 ? 185.0 : 15.0));
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
    previewSkill = null;
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
    if (i < 0 || i >= f.length) return;
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
    previewSkill = null;
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
      if (t.bleeds.length >= 2) t.bleeds.removeAt(0);
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
        title: 'Painel RPG 3D',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(
            primary: kPink,
            onPrimary: Colors.black,
            secondary: kViolet,
            surface: kDeep,
            onSurface: kText,
          ),
          bottomSheetTheme: const BottomSheetThemeData(backgroundColor: kDeep),
        ),
        home: const Home(),
      );
}

void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: kDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );

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
    const pages = [Map3DTab(), CombatTab(), HeroesTab(), RulesTab()];
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
   
