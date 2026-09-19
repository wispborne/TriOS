import 'package:flutter_test/flutter_test.dart';
import 'package:trios/fighter_viewer/wings_manager.dart';
import 'package:trios/utils/extensions.dart';

void main() {
  test('reads fitted weapons by slot, skipping commented-out slots', () {
    // Vanilla broadsword_Fighter.variant, as shipped.
    const raw = '''
{
	"quality":0.5,
	"displayName":"Heavy Fighter",
	"hullId":"broadsword",
	"variantId":"broadsword_Fighter",
	"fluxVents":0,
	"fluxCapacitors":0,
	"hullMods":[], # array of strings

	# mode is either LINKED or ALTERNATING
	# slot ids (WS ***) must match what's in the .ship file
	"weaponGroups":[
		{"mode":"LINKED",
		 "weapons":{
		 			"WS 001":"lightmg",
		 			"WS 002":"lightmg",
		 		   },
		},
		{"mode":"LINKED",
		 "weapons":{
		 			#"WS 003":"swarmer_fighter",
		 		   },
		},
	],
}''';

    expect(weaponsBySlotFromVariant(raw.parseJsonToMap()), {
      'WS 001': 'lightmg',
      'WS 002': 'lightmg',
    });
  });

  test('a variant with no weapon groups has no weapons', () {
    expect(
      weaponsBySlotFromVariant({'hullId': 'x', 'variantId': 'y'}),
      isEmpty,
    );
  });
}
