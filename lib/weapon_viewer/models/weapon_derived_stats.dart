// weapon_derived_stats.dart

import 'dart:math' as math;

import 'package:trios/weapon_viewer/models/weapon.dart';

/// The stats the game derives from a weapon's raw CSV + `.wpn` numbers,
/// transliterated from the game's `WeaponSpreadsheetLoader` (the class that
/// fills in `WeaponAPI.DerivedWeaponStatsAPI`).
///
/// The layout deliberately copies the game's: one branch per shape of weapon
/// — burst beam, continuous beam, projectile — each computing every stat top
/// to bottom. Keeping the same shape makes TriOS's math cheap to diff against
/// the decompiled game code when hunting for gaps, so favor faithfulness to
/// the game's structure over abstraction when changing this file.
class WeaponDerivedStats {
  /// Damage of one full burst. Burst beams only; null otherwise.
  final double? burstDamage;

  /// The refire delay the codex prints. For projectiles this is the game's
  /// `chargedown + burstFireDuration`: the in-burst delays are dropped for
  /// 100+ round bursts, and an interruptible burst shows bare chargedown.
  /// Null only for continuous beams, which have no refire row.
  final double? refireDelay;

  /// Burst DPS — damage per second while firing continuously, ignoring ammo.
  final double? effectiveDps;

  /// Ammo-limited DPS. Null when it wouldn't be shown: the game requires an
  /// `ammo` cap plus `ammo/sec`, and compares against [effectiveDps] with
  /// plain `!=` — even "600 (600)" gets printed when the floats differ.
  final double? sustainedDps;

  final double? fluxPerDamage;
  final double? fluxPerSecond;
  final double? sustainedFluxPerSecond;

  /// EMP damage as shown: per activation for burst beams, per shot/second
  /// otherwise.
  final double? empPerActivation;

  bool get hasSustainedDps => sustainedDps != null;

  const WeaponDerivedStats._({
    required this.burstDamage,
    required this.refireDelay,
    required this.effectiveDps,
    required this.sustainedDps,
    required this.fluxPerDamage,
    required this.fluxPerSecond,
    required this.sustainedFluxPerSecond,
    required this.empPerActivation,
  });

  factory WeaponDerivedStats.of(Weapon spec) {
    if (spec.isBurstBeam) return _burstBeam(spec);
    if (spec.isBeam) return _continuousBeam(spec);
    return _projectile(spec);
  }

  /// A beam that fires in timed pulses: `burst size` holds the beam's uptime
  /// in seconds, not a shot count.
  static WeaponDerivedStats _burstBeam(Weapon spec) {
    final chargeup = spec.chargeup ?? 0.0;
    final chargedown = spec.chargedown ?? 0.0;
    final burstDuration = (spec.burstSize ?? 0).toDouble();

    // 0.333 = average beam intensity during the chargeup/chargedown ramps.
    // A beam that only fires at full charge deals nothing while charging, so
    // the game drops the chargeup term from the ramp — but only here; every
    // duration below keeps the real chargeup.
    final rampChargeup = spec.beamFireOnlyOnFullCharge == true ? 0.0 : chargeup;
    final damageMultiplier =
        (rampChargeup + chargedown) * 0.333 + burstDuration;
    final burstDamage = (spec.damagePerSecond ?? 0.0) * damageMultiplier;

    final refireDelay =
        chargeup + chargedown + burstDuration + (spec.burstDelay ?? 0.0);
    final double? dps = burstDamage > 0 && refireDelay > 0
        ? burstDamage / refireDelay
        : null;

    final double? fluxPerDamage = burstDamage > 0
        ? (spec.energyPerSecond ?? 0.0) *
              (chargeup + burstDuration) /
              burstDamage
        : null;

    // Sustained: one burst per ammo regenerated. Needs an ammo cap — regen
    // without one is ignored, like the game.
    double? sustainedDps;
    if (dps != null && spec.usesAmmo && (spec.ammoPerSec ?? 0) > 0) {
      final s = burstDamage * spec.ammoPerSec!;
      if (s != dps) sustainedDps = s;
    }

    final emp = spec.emp;
    return WeaponDerivedStats._(
      burstDamage: burstDamage,
      refireDelay: refireDelay,
      effectiveDps: dps,
      sustainedDps: sustainedDps,
      fluxPerDamage: fluxPerDamage,
      fluxPerSecond: _fluxPerSecond(spec, dps, fluxPerDamage),
      sustainedFluxPerSecond: _times(sustainedDps, fluxPerDamage),
      empPerActivation: emp != null && emp > 0 ? emp * damageMultiplier : emp,
    );
  }

  /// An always-on beam: DPS and flux come straight from the per-second
  /// columns, and nothing here is per-shot.
  static WeaponDerivedStats _continuousBeam(Weapon spec) {
    final rawDps = spec.damagePerSecond ?? 0;
    final double? dps = rawDps > 0 ? rawDps.toDouble() : null;

    final double? fluxPerDamage = dps != null && (spec.energyPerSecond ?? 0) > 0
        ? spec.energyPerSecond! / dps
        : null;

    return WeaponDerivedStats._(
      burstDamage: null,
      refireDelay: null,
      effectiveDps: dps,
      sustainedDps: null,
      fluxPerDamage: fluxPerDamage,
      fluxPerSecond: _fluxPerSecond(spec, dps, fluxPerDamage),
      sustainedFluxPerSecond: null,
      empPerActivation: spec.emp,
    );
  }

  /// Everything that fires projectiles, missiles included. The game
  /// multiplies each pull's damage and flux by [Weapon.barrelCount] here
  /// (LINKED/DUAL_LINKED barrels fire together), and that multiplier
  /// deliberately cancels out of flux/damage and of sustained DPS.
  static WeaponDerivedStats _projectile(Weapon spec) {
    final chargeup = spec.chargeup ?? 0.0;
    final chargedown = spec.chargedown ?? 0.0;
    final burstDelay = spec.burstDelay ?? 0.0;
    final burstSize = spec.burstSize?.toInt().clamp(1, 99999) ?? 1;
    final barrels = spec.barrelCount;

    // MIRVs deal their submunitions' total, not the CSV number.
    final damagePerShot = spec.mirvTotalDamage ?? spec.damagePerShot;

    // The full firing cycle — the DPS denominator always includes the
    // in-burst delays, whatever the codex prints as the refire delay.
    final cycleTime =
        chargeup +
        chargedown +
        burstDelay * (burstSize > 1 ? (burstSize - 1).toDouble() : 0.0);

    // What the codex prints: `chargedown + burstFireDuration`. Bursts over
    // 100 rounds drop the in-burst delays, and an interruptible burst fires
    // shot-by-shot, so only the chargedown separates pulls.
    final double refireDelay;
    if (spec.interruptibleBurst == true) {
      refireDelay = chargedown;
    } else if (burstSize > 100) {
      refireDelay = chargeup + chargedown;
    } else {
      refireDelay = cycleTime;
    }

    final damagePerPull = (damagePerShot ?? 0.0) * barrels;
    final double? dps = damagePerPull > 0 && cycleTime > 0
        ? damagePerPull * burstSize / cycleTime
        : null;

    // Sustained: the barrels cancel — firing every barrel at once does not
    // refill the magazine any faster. Needs an ammo cap, like the game.
    double? sustainedDps;
    if (dps != null &&
        spec.usesAmmo &&
        (spec.ammoPerSec ?? 0) > 0 &&
        damagePerShot != null) {
      final s = damagePerShot * spec.ammoPerSec!;
      if (s != dps) sustainedDps = s;
    }

    final totalDamage = damagePerPull * burstSize;
    final totalFlux =
        chargeup * (spec.energyPerSecond ?? 0.0) +
        (spec.energyPerShot ?? 0.0) * burstSize * barrels;
    final double? fluxPerDamage = totalFlux > 0
        ? totalFlux / math.max(1.0, totalDamage)
        : null;

    return WeaponDerivedStats._(
      burstDamage: null,
      refireDelay: refireDelay,
      effectiveDps: dps,
      sustainedDps: sustainedDps,
      fluxPerDamage: fluxPerDamage,
      fluxPerSecond: _fluxPerSecond(spec, dps, fluxPerDamage),
      sustainedFluxPerSecond: _times(sustainedDps, fluxPerDamage),
      empPerActivation: spec.emp,
    );
  }

  /// The game's `getFluxPerSecond()` is `dps * fluxPerDam`; beams with no
  /// usable DPS still drain their `energy/second` while firing.
  static double? _fluxPerSecond(
    Weapon spec,
    double? dps,
    double? fluxPerDamage,
  ) {
    if (dps != null && fluxPerDamage != null) return dps * fluxPerDamage;
    if (spec.isBeam && (spec.energyPerSecond ?? 0) > 0) {
      return spec.energyPerSecond!.toDouble();
    }
    return null;
  }

  static double? _times(double? a, double? b) =>
      a != null && b != null ? a * b : null;
}

/// The weapon tooltip's display-layer math, transliterated from the game's
/// tooltip builder (`CargoTooltipFactory`). The game keeps this apart from
/// the derived stats, so TriOS does too: these decide what the tooltip
/// *prints*, never what a stat *is*.
class WeaponTooltipDisplay {
  /// Shots per trigger pull as the tooltip counts them: the CSV burst size
  /// times the barrels that fire together. A twin LINKED cannon with a CSV
  /// burst size of 1 shows "Burst size 2". An interruptible burst fires
  /// shot-by-shot, so only the barrels count. Meaningless for beams.
  final int burstSize;

  /// Whether the "Burst size" row appears (projectiles firing more than one
  /// shot per pull).
  final bool showBurstRow;

  /// Whether the Damage and EMP values get an "xN" suffix. Missiles always
  /// get one when bursting; gun projectiles drop it for giant bursts (1000+)
  /// and when one burst would drain the whole magazine.
  final bool showDamageTimesBurst;

  /// Whether the codex shows this burst beam's per-burst Damage row. Burst
  /// beams with `skipIdleFrameIfZeroBurstDelay` (IR Autolance) display as
  /// continuous beams instead. False for everything that isn't a burst beam.
  final bool displayAsBurstBeam;

  const WeaponTooltipDisplay._({
    required this.burstSize,
    required this.showBurstRow,
    required this.showDamageTimesBurst,
    required this.displayAsBurstBeam,
  });

  factory WeaponTooltipDisplay.of(Weapon spec) {
    final csvBurst = spec.burstSize?.toInt().clamp(1, 99999) ?? 1;
    final burst = spec.isBeam
        ? 1
        : (spec.interruptibleBurst == true ? 1 : csvBurst) * spec.barrelCount;
    final showBurstRow = !spec.isBeam && burst > 1;
    // The game branches on the projectile's class: missiles (a matched
    // missile `.proj`) skip the magazine and giant-burst checks.
    final isMissileProjectile = spec.missileType != null;
    return WeaponTooltipDisplay._(
      burstSize: burst,
      showBurstRow: showBurstRow,
      showDamageTimesBurst:
          showBurstRow &&
          (isMissileProjectile ||
              (burst < 1000 && (spec.ammo == null || spec.ammo! > burst))),
      displayAsBurstBeam:
          spec.isBurstBeam && spec.skipIdleFrameIfZeroBurstDelay != true,
    );
  }
}
