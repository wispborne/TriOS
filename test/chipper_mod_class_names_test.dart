import 'package:flutter_test/flutter_test.dart';
import 'package:trios/chipper/mod_class_names.dart';

/// Every mod class name that [classNameInTextPattern] finds in [text].
List<String> modNamesIn(String text) => classNameInTextPattern
    .allMatches(text)
    .map((match) => match[0]!)
    .where(isModClassName)
    .toList();

void main() {
  group("isModClassName", () {
    test("game and bundled library classes are not mod classes", () {
      for (final name in [
        "com.fs.starfarer.api.impl.codex.CodexDataV2",
        "com.fs.starfarer.loading.scripts.ScriptStore",
        "com.fs.graphics.util.Sprite",
        "sound.Sound",
        "zzz.com.fs.starfarer.Something",
        "java.lang.RuntimeException",
        "javax.xml.bind.JAXBContext",
        "org.lwjgl.opengl.GL11",
        "org.apache.log4j.Logger",
        "org.json.JSONObject",
        "org.codehaus.janino.Compiler",
        "com.thoughtworks.xstream.XStream",
      ]) {
        expect(isModClassName(name), isFalse, reason: name);
      }
    });

    test("mod classes are mod classes", () {
      for (final name in [
        "Arisza.mms.hullmods.microlayerHullmod",
        "org.magiclib.achievements.MagicAchievement",
        "org.lazywizard.lazylib.MathUtils",
        "lunalib.backend.ui.LunaUI",
        "wisp.trios.PortraitReplacer",
        "data.scripts.SomeModPlugin",
      ]) {
        expect(isModClassName(name), isTrue, reason: name);
      }
    });

    test("the Java module in front of a class name is ignored", () {
      expect(isModClassName("java.base/java.io.File"), isFalse);
      expect(isModClassName("java.base/java.lang.Class"), isFalse);
    });

    test("names without a package are never mod classes", () {
      expect(isModClassName("Main"), isFalse);
      expect(isModClassName(""), isFalse);
      expect(isModClassName(null), isFalse);
    });
  });

  group("finding mod class names in message text", () {
    test("picks the mod class out of an error message", () {
      expect(
        modNamesIn(
          "java.lang.RuntimeException: Problem loading class "
          "[Arisza.mms.hullmods.microlayerHullmod]",
        ),
        ["Arisza.mms.hullmods.microlayerHullmod"],
      );
    });

    test("picks the mod class out of a Caused by line", () {
      expect(
        modNamesIn(
          "Caused by: java.lang.NoSuchMethodException: "
          "Arisza.mms.hullmods.microlayerHullmod.<init>()",
        ),
        ["Arisza.mms.hullmods.microlayerHullmod"],
      );
    });

    test("file names and version numbers are not mod classes", () {
      expect(modNamesIn("Loading data/config/settings.json"), isEmpty);
      expect(modNamesIn("Starting Starsector 0.98a-RC8 launcher"), isEmpty);
      expect(modNamesIn("Rotating starsector.log.1"), isEmpty);
    });
  });
}
