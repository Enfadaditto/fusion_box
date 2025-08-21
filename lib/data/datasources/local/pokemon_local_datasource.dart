import 'package:fusion_box/core/errors/exceptions.dart';
import 'package:fusion_box/data/models/pokemon_model.dart';

abstract class PokemonLocalDataSource {
  Future<List<PokemonModel>> getAllPokemon();
  Future<PokemonModel?> getPokemonById(int id);
  Future<List<PokemonModel>> searchPokemon(String query);
}

class PokemonLocalDataSourceImpl implements PokemonLocalDataSource {
  List<PokemonModel>? _cachedPokemon;

  PokemonLocalDataSourceImpl();

  @override
  Future<List<PokemonModel>> getAllPokemon() async {
    try {
      if (_cachedPokemon != null) {
        return _cachedPokemon!;
      }

      // Usar siempre la lista predefinida de Pokemon
      _cachedPokemon = _createBasicPokemonList();

      return _cachedPokemon!;
    } catch (e) {
      throw DataSourceException('Failed to load Pokemon data: $e');
    }
  }

  @override
  Future<PokemonModel?> getPokemonById(int id) async {
    final allPokemon = await getAllPokemon();
    try {
      return allPokemon.firstWhere((pokemon) => pokemon.pokedexNumber == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<PokemonModel>> searchPokemon(String query) async {
    final allPokemon = await getAllPokemon();
    final lowerQuery = query.toLowerCase();

    return allPokemon.where((pokemon) {
      return pokemon.name.toLowerCase().contains(lowerQuery) ||
          pokemon.pokedexNumber.toString().contains(query);
    }).toList();
  }

  // DEPRECATED: Use pokemon_full_list.json instead -> This is a fallback for when the json is missing.
  List<PokemonModel> _createBasicPokemonList() {
    final basicPokemon = <PokemonModel>[];

    final pokemonDatabase = {
      1: {
        'name': 'Bulbasaur',
        'types': ['Grass', 'Poison'],
      },
      2: {
        'name': 'Ivysaur',
        'types': ['Grass', 'Poison'],
      },
      3: {
        'name': 'Venusaur',
        'types': ['Grass', 'Poison'],
      },
      4: {
        'name': 'Charmander',
        'types': ['Fire'],
      },
      5: {
        'name': 'Charmeleon',
        'types': ['Fire'],
      },
      6: {
        'name': 'Charizard',
        'types': ['Fire', 'Flying'],
      },
      7: {
        'name': 'Squirtle',
        'types': ['Water'],
      },
      8: {
        'name': 'Wartortle',
        'types': ['Water'],
      },
      9: {
        'name': 'Blastoise',
        'types': ['Water'],
      },
      10: {
        'name': 'Caterpie',
        'types': ['Bug'],
      },
      11: {
        'name': 'Metapod',
        'types': ['Bug'],
      },
      12: {
        'name': 'Butterfree',
        'types': ['Bug', 'Flying'],
      },
      13: {
        'name': 'Weedle',
        'types': ['Bug', 'Poison'],
      },
      14: {
        'name': 'Kakuna',
        'types': ['Bug', 'Poison'],
      },
      15: {
        'name': 'Beedrill',
        'types': ['Bug', 'Poison'],
      },
      16: {
        'name': 'Pidgey',
        'types': ['Normal', 'Flying'],
      },
      17: {
        'name': 'Pidgeotto',
        'types': ['Normal', 'Flying'],
      },
      18: {
        'name': 'Pidgeot',
        'types': ['Normal', 'Flying'],
      },
      19: {
        'name': 'Rattata',
        'types': ['Normal'],
      },
      20: {
        'name': 'Raticate',
        'types': ['Normal'],
      },
      21: {
        'name': 'Spearow',
        'types': ['Normal', 'Flying'],
      },
      22: {
        'name': 'Fearow',
        'types': ['Normal', 'Flying'],
      },
      23: {
        'name': 'Ekans',
        'types': ['Poison'],
      },
      24: {
        'name': 'Arbok',
        'types': ['Poison'],
      },
      25: {
        'name': 'Pikachu',
        'types': ['Electric'],
      },
      26: {
        'name': 'Raichu',
        'types': ['Electric'],
      },
      27: {
        'name': 'Sandshrew',
        'types': ['Ground'],
      },
      28: {
        'name': 'Sandslash',
        'types': ['Ground'],
      },
      29: {
        'name': 'Nidoran♀',
        'types': ['Poison'],
      },
      30: {
        'name': 'Nidorina',
        'types': ['Poison'],
      },
      31: {
        'name': 'Nidoqueen',
        'types': ['Poison', 'Ground'],
      },
      32: {
        'name': 'Nidoran♂',
        'types': ['Poison'],
      },
      33: {
        'name': 'Nidorino',
        'types': ['Poison'],
      },
      34: {
        'name': 'Nidoking',
        'types': ['Poison', 'Ground'],
      },
      35: {
        'name': 'Clefairy',
        'types': ['Fairy'],
      },
      36: {
        'name': 'Clefable',
        'types': ['Fairy'],
      },
      37: {
        'name': 'Vulpix',
        'types': ['Fire'],
      },
      38: {
        'name': 'Ninetales',
        'types': ['Fire'],
      },
      39: {
        'name': 'Jigglypuff',
        'types': ['Normal', 'Fairy'],
      },
      40: {
        'name': 'Wigglytuff',
        'types': ['Normal', 'Fairy'],
      },
      41: {
        'name': 'Zubat',
        'types': ['Poison', 'Flying'],
      },
      42: {
        'name': 'Golbat',
        'types': ['Poison', 'Flying'],
      },
      43: {
        'name': 'Oddish',
        'types': ['Grass', 'Poison'],
      },
      44: {
        'name': 'Gloom',
        'types': ['Grass', 'Poison'],
      },
      45: {
        'name': 'Vileplume',
        'types': ['Grass', 'Poison'],
      },
      46: {
        'name': 'Paras',
        'types': ['Bug', 'Grass'],
      },
      47: {
        'name': 'Parasect',
        'types': ['Bug', 'Grass'],
      },
      48: {
        'name': 'Venonat',
        'types': ['Bug', 'Poison'],
      },
      49: {
        'name': 'Venomoth',
        'types': ['Bug', 'Poison'],
      },
      50: {
        'name': 'Diglett',
        'types': ['Ground'],
      },
      51: {
        'name': 'Dugtrio',
        'types': ['Ground'],
      },
      52: {
        'name': 'Meowth',
        'types': ['Normal'],
      },
      53: {
        'name': 'Persian',
        'types': ['Normal'],
      },
      54: {
        'name': 'Psyduck',
        'types': ['Water'],
      },
      55: {
        'name': 'Golduck',
        'types': ['Water'],
      },
      56: {
        'name': 'Mankey',
        'types': ['Fighting'],
      },
      57: {
        'name': 'Primeape',
        'types': ['Fighting'],
      },
      58: {
        'name': 'Growlithe',
        'types': ['Fire'],
      },
      59: {
        'name': 'Arcanine',
        'types': ['Fire'],
      },
      60: {
        'name': 'Poliwag',
        'types': ['Water'],
      },
      61: {
        'name': 'Poliwhirl',
        'types': ['Water'],
      },
      62: {
        'name': 'Poliwrath',
        'types': ['Water', 'Fighting'],
      },
      63: {
        'name': 'Abra',
        'types': ['Psychic'],
      },
      64: {
        'name': 'Kadabra',
        'types': ['Psychic'],
      },
      65: {
        'name': 'Alakazam',
        'types': ['Psychic'],
      },
      66: {
        'name': 'Machop',
        'types': ['Fighting'],
      },
      67: {
        'name': 'Machoke',
        'types': ['Fighting'],
      },
      68: {
        'name': 'Machamp',
        'types': ['Fighting'],
      },
      69: {
        'name': 'Bellsprout',
        'types': ['Grass', 'Poison'],
      },
      70: {
        'name': 'Weepinbell',
        'types': ['Grass', 'Poison'],
      },
      71: {
        'name': 'Victreebel',
        'types': ['Grass', 'Poison'],
      },
      72: {
        'name': 'Tentacool',
        'types': ['Water', 'Poison'],
      },
      73: {
        'name': 'Tentacruel',
        'types': ['Water', 'Poison'],
      },
      74: {
        'name': 'Geodude',
        'types': ['Rock', 'Ground'],
      },
      75: {
        'name': 'Graveler',
        'types': ['Rock', 'Ground'],
      },
      76: {
        'name': 'Golem',
        'types': ['Rock', 'Ground'],
      },
      77: {
        'name': 'Ponyta',
        'types': ['Fire'],
      },
      78: {
        'name': 'Rapidash',
        'types': ['Fire'],
      },
      79: {
        'name': 'Slowpoke',
        'types': ['Water', 'Psychic'],
      },
      80: {
        'name': 'Slowbro',
        'types': ['Water', 'Psychic'],
      },
      81: {
        'name': 'Magnemite',
        'types': ['Electric', 'Steel'],
      },
      82: {
        'name': 'Magneton',
        'types': ['Electric', 'Steel'],
      },
      83: {
        'name': 'Farfetch\'d',
        'types': ['Normal', 'Flying'],
      },
      84: {
        'name': 'Doduo',
        'types': ['Normal', 'Flying'],
      },
      85: {
        'name': 'Dodrio',
        'types': ['Normal', 'Flying'],
      },
      86: {
        'name': 'Seel',
        'types': ['Water'],
      },
      87: {
        'name': 'Dewgong',
        'types': ['Water', 'Ice'],
      },
      88: {
        'name': 'Grimer',
        'types': ['Poison'],
      },
      89: {
        'name': 'Muk',
        'types': ['Poison'],
      },
      90: {
        'name': 'Shellder',
        'types': ['Water'],
      },
      91: {
        'name': 'Cloyster',
        'types': ['Water', 'Ice'],
      },
      92: {
        'name': 'Gastly',
        'types': ['Ghost', 'Poison'],
      },
      93: {
        'name': 'Haunter',
        'types': ['Ghost', 'Poison'],
      },
      94: {
        'name': 'Gengar',
        'types': ['Ghost', 'Poison'],
      },
      95: {
        'name': 'Onix',
        'types': ['Rock', 'Ground'],
      },
      96: {
        'name': 'Drowzee',
        'types': ['Psychic'],
      },
      97: {
        'name': 'Hypno',
        'types': ['Psychic'],
      },
      98: {
        'name': 'Krabby',
        'types': ['Water'],
      },
      99: {
        'name': 'Kingler',
        'types': ['Water'],
      },
      100: {
        'name': 'Voltorb',
        'types': ['Electric'],
      },
      101: {
        'name': 'Electrode',
        'types': ['Electric'],
      },
      102: {
        'name': 'Exeggcute',
        'types': ['Grass', 'Psychic'],
      },
      103: {
        'name': 'Exeggutor',
        'types': ['Grass', 'Psychic'],
      },
      104: {
        'name': 'Cubone',
        'types': ['Ground'],
      },
      105: {
        'name': 'Marowak',
        'types': ['Ground'],
      },
      106: {
        'name': 'Hitmonlee',
        'types': ['Fighting'],
      },
      107: {
        'name': 'Hitmonchan',
        'types': ['Fighting'],
      },
      108: {
        'name': 'Lickitung',
        'types': ['Normal'],
      },
      109: {
        'name': 'Koffing',
        'types': ['Poison'],
      },
      110: {
        'name': 'Weezing',
        'types': ['Poison'],
      },
      111: {
        'name': 'Rhyhorn',
        'types': ['Ground', 'Rock'],
      },
      112: {
        'name': 'Rhydon',
        'types': ['Ground', 'Rock'],
      },
      113: {
        'name': 'Chansey',
        'types': ['Normal'],
      },
      114: {
        'name': 'Tangela',
        'types': ['Grass'],
      },
      115: {
        'name': 'Kangaskhan',
        'types': ['Normal'],
      },
      116: {
        'name': 'Horsea',
        'types': ['Water'],
      },
      117: {
        'name': 'Seadra',
        'types': ['Water'],
      },
      118: {
        'name': 'Goldeen',
        'types': ['Water'],
      },
      119: {
        'name': 'Seaking',
        'types': ['Water'],
      },
      120: {
        'name': 'Staryu',
        'types': ['Water'],
      },
      121: {
        'name': 'Starmie',
        'types': ['Water', 'Psychic'],
      },
      122: {
        'name': 'Mr. Mime',
        'types': ['Psychic', 'Fairy'],
      },
      123: {
        'name': 'Scyther',
        'types': ['Bug', 'Flying'],
      },
      124: {
        'name': 'Jynx',
        'types': ['Ice', 'Psychic'],
      },
      125: {
        'name': 'Electabuzz',
        'types': ['Electric'],
      },
      126: {
        'name': 'Magmar',
        'types': ['Fire'],
      },
      127: {
        'name': 'Pinsir',
        'types': ['Bug'],
      },
      128: {
        'name': 'Tauros',
        'types': ['Normal'],
      },
      129: {
        'name': 'Magikarp',
        'types': ['Water'],
      },
      130: {
        'name': 'Gyarados',
        'types': ['Water', 'Flying'],
      },
      131: {
        'name': 'Lapras',
        'types': ['Water', 'Ice'],
      },
      132: {
        'name': 'Ditto',
        'types': ['Normal'],
      },
      133: {
        'name': 'Eevee',
        'types': ['Normal'],
      },
      134: {
        'name': 'Vaporeon',
        'types': ['Water'],
      },
      135: {
        'name': 'Jolteon',
        'types': ['Electric'],
      },
      136: {
        'name': 'Flareon',
        'types': ['Fire'],
      },
      137: {
        'name': 'Porygon',
        'types': ['Normal'],
      },
      138: {
        'name': 'Omanyte',
        'types': ['Rock', 'Water'],
      },
      139: {
        'name': 'Omastar',
        'types': ['Rock', 'Water'],
      },
      140: {
        'name': 'Kabuto',
        'types': ['Rock', 'Water'],
      },
      141: {
        'name': 'Kabutops',
        'types': ['Rock', 'Water'],
      },
      142: {
        'name': 'Aerodactyl',
        'types': ['Rock', 'Flying'],
      },
      143: {
        'name': 'Snorlax',
        'types': ['Normal'],
      },
      144: {
        'name': 'Articuno',
        'types': ['Ice', 'Flying'],
      },
      145: {
        'name': 'Zapdos',
        'types': ['Electric', 'Flying'],
      },
      146: {
        'name': 'Moltres',
        'types': ['Fire', 'Flying'],
      },
      147: {
        'name': 'Dratini',
        'types': ['Dragon'],
      },
      148: {
        'name': 'Dragonair',
        'types': ['Dragon'],
      },
      149: {
        'name': 'Dragonite',
        'types': ['Dragon', 'Flying'],
      },
      150: {
        'name': 'Mewtwo',
        'types': ['Psychic'],
      },
      151: {
        'name': 'Mew',
        'types': ['Psychic'],
      },
      152: {
        'name': 'Chikorita',
        'types': ['Grass'],
      },
      153: {
        'name': 'Bayleef',
        'types': ['Grass'],
      },
      154: {
        'name': 'Meganium',
        'types': ['Grass'],
      },
      155: {
        'name': 'Cyndaquil',
        'types': ['Fire'],
      },
      156: {
        'name': 'Quilava',
        'types': ['Fire'],
      },
      157: {
        'name': 'Typhlosion',
        'types': ['Fire'],
      },
      158: {
        'name': 'Totodile',
        'types': ['Water'],
      },
      159: {
        'name': 'Croconaw',
        'types': ['Water'],
      },
      160: {
        'name': 'Feraligatr',
        'types': ['Water'],
      },
      161: {
        'name': 'Sentret',
        'types': ['Normal'],
      },
      162: {
        'name': 'Furret',
        'types': ['Normal'],
      },
      163: {
        'name': 'Hoothoot',
        'types': ['Normal', 'Flying'],
      },
      164: {
        'name': 'Noctowl',
        'types': ['Normal', 'Flying'],
      },
      165: {
        'name': 'Ledyba',
        'types': ['Bug', 'Flying'],
      },
      166: {
        'name': 'Ledian',
        'types': ['Bug', 'Flying'],
      },
      167: {
        'name': 'Spinarak',
        'types': ['Bug', 'Poison'],
      },
      168: {
        'name': 'Ariados',
        'types': ['Bug', 'Poison'],
      },
      169: {
        'name': 'Crobat',
        'types': ['Poison', 'Flying'],
      },
      170: {
        'name': 'Chinchou',
        'types': ['Water', 'Electric'],
      },
      171: {
        'name': 'Lanturn',
        'types': ['Water', 'Electric'],
      },
      172: {
        'name': 'Pichu',
        'types': ['Electric'],
      },
      173: {
        'name': 'Cleffa',
        'types': ['Fairy'],
      },
      174: {
        'name': 'Igglybuff',
        'types': ['Normal', 'Fairy'],
      },
      175: {
        'name': 'Togepi',
        'types': ['Fairy'],
      },
      176: {
        'name': 'Togetic',
        'types': ['Fairy', 'Flying'],
      },
      177: {
        'name': 'Natu',
        'types': ['Psychic', 'Flying'],
      },
      178: {
        'name': 'Xatu',
        'types': ['Psychic', 'Flying'],
      },
      179: {
        'name': 'Mareep',
        'types': ['Electric'],
      },
      180: {
        'name': 'Flaaffy',
        'types': ['Electric'],
      },
      181: {
        'name': 'Ampharos',
        'types': ['Electric'],
      },
      182: {
        'name': 'Bellossom',
        'types': ['Grass'],
      },
      183: {
        'name': 'Marill',
        'types': ['Water', 'Fairy'],
      },
      184: {
        'name': 'Azumarill',
        'types': ['Water', 'Fairy'],
      },
      185: {
        'name': 'Sudowoodo',
        'types': ['Rock'],
      },
      186: {
        'name': 'Politoed',
        'types': ['Water'],
      },
      187: {
        'name': 'Hoppip',
        'types': ['Grass', 'Flying'],
      },
      188: {
        'name': 'Skiploom',
        'types': ['Grass', 'Flying'],
      },
      189: {
        'name': 'Jumpluff',
        'types': ['Grass', 'Flying'],
      },
      190: {
        'name': 'Aipom',
        'types': ['Normal'],
      },
      191: {
        'name': 'Sunkern',
        'types': ['Grass'],
      },
      192: {
        'name': 'Sunflora',
        'types': ['Grass'],
      },
      193: {
        'name': 'Yanma',
        'types': ['Bug', 'Flying'],
      },
      194: {
        'name': 'Wooper',
        'types': ['Water', 'Ground'],
      },
      195: {
        'name': 'Quagsire',
        'types': ['Water', 'Ground'],
      },
      196: {
        'name': 'Espeon',
        'types': ['Psychic'],
      },
      197: {
        'name': 'Umbreon',
        'types': ['Dark'],
      },
      198: {
        'name': 'Murkrow',
        'types': ['Dark', 'Flying'],
      },
      199: {
        'name': 'Slowking',
        'types': ['Water', 'Psychic'],
      },
      200: {
        'name': 'Misdreavus',
        'types': ['Ghost'],
      },
      201: {
        'name': 'Unown',
        'types': ['Psychic'],
      },
      202: {
        'name': 'Wobbuffet',
        'types': ['Psychic'],
      },
      203: {
        'name': 'Girafarig',
        'types': ['Normal', 'Psychic'],
      },
      204: {
        'name': 'Pineco',
        'types': ['Bug'],
      },
      205: {
        'name': 'Forretress',
        'types': ['Bug', 'Steel'],
      },
      206: {
        'name': 'Dunsparce',
        'types': ['Normal'],
      },
      207: {
        'name': 'Gligar',
        'types': ['Ground', 'Flying'],
      },
      208: {
        'name': 'Steelix',
        'types': ['Steel', 'Ground'],
      },
      209: {
        'name': 'Snubbull',
        'types': ['Fairy'],
      },
      210: {
        'name': 'Granbull',
        'types': ['Fairy'],
      },
      211: {
        'name': 'Qwilfish',
        'types': ['Water', 'Poison'],
      },
      212: {
        'name': 'Scizor',
        'types': ['Bug', 'Steel'],
      },
      213: {
        'name': 'Shuckle',
        'types': ['Bug', 'Rock'],
      },
      214: {
        'name': 'Heracross',
        'types': ['Bug', 'Fighting'],
      },
      215: {
        'name': 'Sneasel',
        'types': ['Dark', 'Ice'],
      },
      216: {
        'name': 'Teddiursa',
        'types': ['Normal'],
      },
      217: {
        'name': 'Ursaring',
        'types': ['Normal'],
      },
      218: {
        'name': 'Slugma',
        'types': ['Fire'],
      },
      219: {
        'name': 'Magcargo',
        'types': ['Fire', 'Rock'],
      },
      220: {
        'name': 'Swinub',
        'types': ['Ice', 'Ground'],
      },
      221: {
        'name': 'Piloswine',
        'types': ['Ice', 'Ground'],
      },
      222: {
        'name': 'Corsola',
        'types': ['Water', 'Rock'],
      },
      223: {
        'name': 'Remoraid',
        'types': ['Water'],
      },
      224: {
        'name': 'Octillery',
        'types': ['Water'],
      },
      225: {
        'name': 'Delibird',
        'types': ['Ice', 'Flying'],
      },
      226: {
        'name': 'Mantine',
        'types': ['Water', 'Flying'],
      },
      227: {
        'name': 'Skarmory',
        'types': ['Steel', 'Flying'],
      },
      228: {
        'name': 'Houndour',
        'types': ['Dark', 'Fire'],
      },
      229: {
        'name': 'Houndoom',
        'types': ['Dark', 'Fire'],
      },
      230: {
        'name': 'Kingdra',
        'types': ['Water', 'Dragon'],
      },
      231: {
        'name': 'Phanpy',
        'types': ['Ground'],
      },
      232: {
        'name': 'Donphan',
        'types': ['Ground'],
      },
      233: {
        'name': 'Porygon2',
        'types': ['Normal'],
      },
      234: {
        'name': 'Stantler',
        'types': ['Normal'],
      },
      235: {
        'name': 'Smeargle',
        'types': ['Normal'],
      },
      236: {
        'name': 'Tyrogue',
        'types': ['Fighting'],
      },
      237: {
        'name': 'Hitmontop',
        'types': ['Fighting'],
      },
      238: {
        'name': 'Smoochum',
        'types': ['Ice', 'Psychic'],
      },
      239: {
        'name': 'Elekid',
        'types': ['Electric'],
      },
      240: {
        'name': 'Magby',
        'types': ['Fire'],
      },
      241: {
        'name': 'Miltank',
        'types': ['Normal'],
      },
      242: {
        'name': 'Blissey',
        'types': ['Normal'],
      },
      243: {
        'name': 'Raikou',
        'types': ['Electric'],
      },
      244: {
        'name': 'Entei',
        'types': ['Fire'],
      },
      245: {
        'name': 'Suicune',
        'types': ['Water'],
      },
      246: {
        'name': 'Larvitar',
        'types': ['Rock', 'Ground'],
      },
      247: {
        'name': 'Pupitar',
        'types': ['Rock', 'Ground'],
      },
      248: {
        'name': 'Tyranitar',
        'types': ['Rock', 'Dark'],
      },
      249: {
        'name': 'Lugia',
        'types': ['Psychic', 'Flying'],
      },
      250: {
        'name': 'Ho-Oh',
        'types': ['Fire', 'Flying'],
      },
      251: {
        'name': 'Celebi',
        'types': ['Psychic', 'Grass'],
      },

      // Generation III (252-386) - Order matches FusionDex.org
      252: {
        'name': 'Azurill',
        'types': ['Normal', 'Fairy'],
      },
      253: {
        'name': 'Wynaut',
        'types': ['Psychic'],
      },
      254: {
        'name': 'Ambipom',
        'types': ['Normal'],
      },
      255: {
        'name': 'Mismagius',
        'types': ['Ghost'],
      },
      256: {
        'name': 'Honchkrow',
        'types': ['Dark', 'Flying'],
      },
      257: {
        'name': 'Bonsly',
        'types': ['Rock'],
      },
      258: {
        'name': 'Mime Jr.',
        'types': ['Psychic'],
      },
      259: {
        'name': 'Happiny',
        'types': ['Normal'],
      },
      260: {
        'name': 'Munchlax',
        'types': ['Normal'],
      },
      261: {
        'name': 'Mantyke',
        'types': ['Water', 'Flying'],
      },
      262: {
        'name': 'Weavile',
        'types': ['Dark', 'Ice'],
      },
      263: {
        'name': 'Magnezone',
        'types': ['Electric', 'Steel'],
      },
      264: {
        'name': 'Lickilicky',
        'types': ['Normal'],
      },
      265: {
        'name': 'Rhyperior',
        'types': ['Ground', 'Rock'],
      },
      266: {
        'name': 'Tangrowth',
        'types': ['Grass'],
      },
      267: {
        'name': 'Electivire',
        'types': ['Electric'],
      },
      268: {
        'name': 'Magmortar',
        'types': ['Fire'],
      },
      269: {
        'name': 'Togekiss',
        'types': ['Fairy', 'Flying'],
      },
      270: {
        'name': 'Yanmega',
        'types': ['Bug', 'Flying'],
      },
      271: {
        'name': 'Leafeon',
        'types': ['Grass'],
      },
      272: {
        'name': 'Glaceon',
        'types': ['Ice'],
      },
      273: {
        'name': 'Gliscor',
        'types': ['Ground', 'Flying'],
      },
      274: {
        'name': 'Mamoswine',
        'types': ['Ice', 'Ground'],
      },
      275: {
        'name': 'Porygon-Z',
        'types': ['Normal'],
      },
      276: {
        'name': 'Treecko',
        'types': ['Grass'],
      },
      277: {
        'name': 'Grovyle',
        'types': ['Grass'],
      },
      278: {
        'name': 'Sceptile',
        'types': ['Grass'],
      },
      279: {
        'name': 'Torchic',
        'types': ['Fire'],
      },
      280: {
        'name': 'Combusken',
        'types': ['Fire', 'Fighting'],
      },
      281: {
        'name': 'Blaziken',
        'types': ['Fire', 'Fighting'],
      },
      282: {
        'name': 'Mudkip',
        'types': ['Water'],
      },
      283: {
        'name': 'Marshtomp',
        'types': ['Water', 'Ground'],
      },
      284: {
        'name': 'Swampert',
        'types': ['Water', 'Ground'],
      },
      285: {
        'name': 'Ralts',
        'types': ['Psychic', 'Fairy'],
      },
      286: {
        'name': 'Kirlia',
        'types': ['Psychic', 'Fairy'],
      },
      287: {
        'name': 'Gardevoir',
        'types': ['Psychic', 'Fairy'],
      },
      288: {
        'name': 'Gallade',
        'types': ['Psychic', 'Fighting'],
      },
      289: {
        'name': 'Shedinja',
        'types': ['Bug', 'Ghost'],
      },
      290: {
        'name': 'Kecleon',
        'types': ['Normal'],
      },
      291: {
        'name': 'Beldum',
        'types': ['Steel', 'Psychic'],
      },
      292: {
        'name': 'Metang',
        'types': ['Steel', 'Psychic'],
      },
      293: {
        'name': 'Metagross',
        'types': ['Steel', 'Psychic'],
      },
      294: {
        'name': 'Bidoof',
        'types': ['Normal'],
      },
      295: {
        'name': 'Spiritomb',
        'types': ['Ghost', 'Dark'],
      },
      296: {
        'name': 'Lucario',
        'types': ['Fighting', 'Steel'],
      },
      297: {
        'name': 'Gible',
        'types': ['Dragon', 'Ground'],
      },
      298: {
        'name': 'Gabite',
        'types': ['Dragon', 'Ground'],
      },
      299: {
        'name': 'Garchomp',
        'types': ['Dragon', 'Ground'],
      },
      300: {
        'name': 'Mawile',
        'types': ['Steel', 'Fairy'],
      },
      301: {
        'name': 'Lileep',
        'types': ['Rock', 'Grass'],
      },
      302: {
        'name': 'Cradily',
        'types': ['Rock', 'Grass'],
      },
      303: {
        'name': 'Anorith',
        'types': ['Rock', 'Bug'],
      },
      304: {
        'name': 'Armaldo',
        'types': ['Rock', 'Bug'],
      },
      305: {
        'name': 'Cranidos',
        'types': ['Rock'],
      },
      306: {
        'name': 'Rampardos',
        'types': ['Rock'],
      },
      307: {
        'name': 'Shieldon',
        'types': ['Rock', 'Steel'],
      },
      308: {
        'name': 'Bastiodon',
        'types': ['Rock', 'Steel'],
      },
      309: {
        'name': 'Slaking',
        'types': ['Normal'],
      },
      310: {
        'name': 'Absol',
        'types': ['Dark'],
      },
      311: {
        'name': 'Duskull',
        'types': ['Ghost'],
      },
      312: {
        'name': 'Dusclops',
        'types': ['Ghost'],
      },
      313: {
        'name': 'Dusknoir',
        'types': ['Ghost'],
      },
      314: {
        'name': 'Wailord',
        'types': ['Water'],
      },
      315: {
        'name': 'Arceus',
        'types': ['Normal'],
      },
      316: {
        'name': 'Turtwig',
        'types': ['Grass'],
      },
      317: {
        'name': 'Grotle',
        'types': ['Grass'],
      },
      318: {
        'name': 'Torterra',
        'types': ['Grass', 'Ground'],
      },
      319: {
        'name': 'Chimchar',
        'types': ['Fire'],
      },
      320: {
        'name': 'Monferno',
        'types': ['Fire', 'Fighting'],
      },
      321: {
        'name': 'Infernape',
        'types': ['Fire', 'Fighting'],
      },
      322: {
        'name': 'Piplup',
        'types': ['Water'],
      },
      323: {
        'name': 'Prinplup',
        'types': ['Water'],
      },
      324: {
        'name': 'Empoleon',
        'types': ['Water', 'Steel'],
      },
      325: {
        'name': 'Nosepass',
        'types': ['Rock'],
      },
      326: {
        'name': 'Probopass',
        'types': ['Rock', 'Steel'],
      },
      327: {
        'name': 'Honedge',
        'types': ['Steel', 'Ghost'],
      },
      328: {
        'name': 'Doublade',
        'types': ['Steel', 'Ghost'],
      },
      329: {
        'name': 'Aegislash',
        'types': ['Steel', 'Ghost'],
      },
      330: {
        'name': 'Pawniard',
        'types': ['Dark', 'Steel'],
      },
      331: {
        'name': 'Bisharp',
        'types': ['Dark', 'Steel'],
      },
      332: {
        'name': 'Luxray',
        'types': ['Electric'],
      },
      333: {
        'name': 'Aggron',
        'types': ['Steel', 'Rock'],
      },
      334: {
        'name': 'Flygon',
        'types': ['Ground', 'Dragon'],
      },
      335: {
        'name': 'Milotic',
        'types': ['Water'],
      },
      336: {
        'name': 'Salamence',
        'types': ['Dragon', 'Flying'],
      },
      337: {
        'name': 'Klinklang',
        'types': ['Steel'],
      },
      338: {
        'name': 'Zoroark',
        'types': ['Dark'],
      },
      339: {
        'name': 'Sylveon',
        'types': ['Fairy'],
      },
      340: {
        'name': 'Kyogre',
        'types': ['Water'],
      },
      341: {
        'name': 'Groudon',
        'types': ['Ground'],
      },
      342: {
        'name': 'Rayquaza',
        'types': ['Dragon', 'Flying'],
      },
      343: {
        'name': 'Dialga',
        'types': ['Steel', 'Dragon'],
      },
      344: {
        'name': 'Palkia',
        'types': ['Water', 'Dragon'],
      },
      345: {
        'name': 'Giratina',
        'types': ['Ghost', 'Dragon'],
      },
      346: {
        'name': 'Regigigas',
        'types': ['Normal'],
      },
      347: {
        'name': 'Darkrai',
        'types': ['Dark'],
      },
      348: {
        'name': 'Genesect',
        'types': ['Bug', 'Steel'],
      },
      349: {
        'name': 'Reshiram',
        'types': ['Dragon', 'Fire'],
      },
      350: {
        'name': 'Zekrom',
        'types': ['Dragon', 'Electric'],
      },
      351: {
        'name': 'Kyurem',
        'types': ['Dragon', 'Ice'],
      },
      352: {
        'name': 'Roserade',
        'types': ['Grass', 'Poison'],
      },
      353: {
        'name': 'Drifblim',
        'types': ['Ghost', 'Flying'],
      },
      354: {
        'name': 'Lopunny',
        'types': ['Normal'],
      },
      355: {
        'name': 'Breloom',
        'types': ['Grass', 'Fighting'],
      },
      356: {
        'name': 'Ninjask',
        'types': ['Bug', 'Flying'],
      },
      357: {
        'name': 'Banette',
        'types': ['Ghost'],
      },
      358: {
        'name': 'Rotom',
        'types': ['Electric', 'Ghost'],
      },
      359: {
        'name': 'Reuniclus',
        'types': ['Psychic'],
      },
      360: {
        'name': 'Whimsicott',
        'types': ['Grass', 'Fairy'],
      },
      361: {
        'name': 'Krookodile',
        'types': ['Ground', 'Dark'],
      },
      362: {
        'name': 'Cofagrigus',
        'types': ['Ghost'],
      },
      363: {
        'name': 'Galvantula',
        'types': ['Bug', 'Electric'],
      },
      364: {
        'name': 'Ferrothorn',
        'types': ['Grass', 'Steel'],
      },
      365: {
        'name': 'Litwick',
        'types': ['Ghost', 'Fire'],
      },
      366: {
        'name': 'Lampent',
        'types': ['Ghost', 'Fire'],
      },
      367: {
        'name': 'Chandelure',
        'types': ['Ghost', 'Fire'],
      },
      368: {
        'name': 'Haxorus',
        'types': ['Dragon'],
      },
      369: {
        'name': 'Golurk',
        'types': ['Ghost', 'Ground'],
      },
      370: {
        'name': 'Pyukumuku',
        'types': ['Water'],
      },
      371: {
        'name': 'Klefki',
        'types': ['Steel', 'Fairy'],
      },
      372: {
        'name': 'Talonflame',
        'types': ['Fire', 'Flying'],
      },
      373: {
        'name': 'Mimikyu',
        'types': ['Ghost', 'Fairy'],
      },
      374: {
        'name': 'Volcarona',
        'types': ['Bug', 'Fire'],
      },
      375: {
        'name': 'Deino',
        'types': ['Dark', 'Dragon'],
      },
      376: {
        'name': 'Zweilous',
        'types': ['Dark', 'Dragon'],
      },
      377: {
        'name': 'Hydreigon',
        'types': ['Dragon', 'Dark'],
      },
      378: {
        'name': 'Latias',
        'types': ['Dragon', 'Psychic'],
      },
      379: {
        'name': 'Latios',
        'types': ['Dragon', 'Psychic'],
      },
      380: {
        'name': 'Deoxys',
        'types': ['Psychic'],
      },
      381: {
        'name': 'Jirachi',
        'types': ['Steel', 'Psychic'],
      },
      382: {
        'name': 'Nincada',
        'types': ['Bug', 'Ground'],
      },
      383: {
        'name': 'Bibarel',
        'types': ['Normal', 'Water'],
      },
      384: {
        'name': 'Riolu',
        'types': ['Fighting'],
      },
      385: {
        'name': 'Slakoth',
        'types': ['Normal'],
      },
      386: {
        'name': 'Vigoroth',
        'types': ['Normal'],
      },
      387: {
        'name': 'Wailmer',
        'types': ['Water'],
      },
      388: {
        'name': 'Shinx',
        'types': ['Electric'],
      },
      389: {
        'name': 'Luxio',
        'types': ['Electric'],
      },
      390: {
        'name': 'Aron',
        'types': ['Steel', 'Rock'],
      },
      391: {
        'name': 'Lairon',
        'types': ['Steel', 'Rock'],
      },
      392: {
        'name': 'Trapinch',
        'types': ['Ground'],
      },
      393: {
        'name': 'Vibrava',
        'types': ['Dragon', 'Ground'],
      },
      394: {
        'name': 'Feebas',
        'types': ['Water'],
      },
      395: {
        'name': 'Bagon',
        'types': ['Dragon'],
      },
      396: {
        'name': 'Shelgon',
        'types': ['Dragon'],
      },
      397: {
        'name': 'Klink',
        'types': ['Steel'],
      },
      398: {
        'name': 'Klang',
        'types': ['Steel'],
      },
      399: {
        'name': 'Zorua',
        'types': ['Dark'],
      },
      400: {
        'name': 'Budew',
        'types': ['Grass', 'Poison'],
      },
      401: {
        'name': 'Roselia',
        'types': ['Grass', 'Poison'],
      },
      402: {
        'name': 'Drifloon',
        'types': ['Ghost', 'Flying'],
      },
      403: {
        'name': 'Buneary',
        'types': ['Normal'],
      },
      404: {
        'name': 'Shroomish',
        'types': ['Grass'],
      },
      405: {
        'name': 'Shuppet',
        'types': ['Ghost'],
      },
      406: {
        'name': 'Solosis',
        'types': ['Psychic'],
      },
      407: {
        'name': 'Duosion',
        'types': ['Psychic'],
      },
      408: {
        'name': 'Cottonee',
        'types': ['Grass', 'Fairy'],
      },
      409: {
        'name': 'Sandile',
        'types': ['Ground', 'Dark'],
      },
      410: {
        'name': 'Krokorok',
        'types': ['Ground', 'Dark'],
      },
      411: {
        'name': 'Yamask',
        'types': ['Ghost'],
      },
      412: {
        'name': 'Joltik',
        'types': ['Bug', 'Electric'],
      },
      413: {
        'name': 'Ferroseed',
        'types': ['Grass', 'Steel'],
      },
      414: {
        'name': 'Axew',
        'types': ['Dragon'],
      },
      415: {
        'name': 'Fraxure',
        'types': ['Dragon'],
      },
      416: {
        'name': 'Golett',
        'types': ['Ground', 'Ghost'],
      },
      417: {
        'name': 'Fletchling',
        'types': ['Normal', 'Flying'],
      },
      418: {
        'name': 'Fletchinder',
        'types': ['Fire', 'Flying'],
      },
      419: {
        'name': 'Larvesta',
        'types': ['Bug', 'Fire'],
      },
      420: {
        'name': 'Stunfisk',
        'types': ['Ground', 'Electric'],
      },
      421: {
        'name': 'Sableye',
        'types': ['Dark', 'Ghost'],
      },
      422: {
        'name': 'Venipede',
        'types': ['Bug', 'Poison'],
      },
      423: {
        'name': 'Whirlipede',
        'types': ['Bug', 'Poison'],
      },
      424: {
        'name': 'Scolipede',
        'types': ['Bug', 'Poison'],
      },
      425: {
        'name': 'Tyrunt',
        'types': ['Rock', 'Dragon'],
      },
      426: {
        'name': 'Tyrantrum',
        'types': ['Rock', 'Dragon'],
      },
      427: {
        'name': 'Snorunt',
        'types': ['Ice'],
      },
      428: {
        'name': 'Glalie',
        'types': ['Ice'],
      },
      429: {
        'name': 'Froslass',
        'types': ['Ice', 'Ghost'],
      },
      430: {
        'name': 'Oricorio Baile',
        'types': ['Fire', 'Flying'],
      },
      431: {
        'name': 'Oricorio Pom-pom',
        'types': ['Electric', 'Flying'],
      },
      432: {
        'name': 'Oricorio Pa-u',
        'types': ['Psychic', 'Flying'],
      },
      433: {
        'name': 'Oricorio Sensu',
        'types': ['Ghost', 'Flying'],
      },
      434: {
        'name': 'Trubbish',
        'types': ['Poison'],
      },
      435: {
        'name': 'Garbodor',
        'types': ['Poison'],
      },
      436: {
        'name': 'Carvanha',
        'types': ['Water', 'Dark'],
      },
      437: {
        'name': 'Sharpedo',
        'types': ['Water', 'Dark'],
      },
      438: {
        'name': 'Phantump',
        'types': ['Ghost', 'Grass'],
      },
      439: {
        'name': 'Trevenant',
        'types': ['Ghost', 'Grass'],
      },
      440: {
        'name': 'Noibat',
        'types': ['Flying', 'Dragon'],
      },
      441: {
        'name': 'Noivern',
        'types': ['Flying', 'Dragon'],
      },
      442: {
        'name': 'Swablu',
        'types': ['Normal', 'Flying'],
      },
      443: {
        'name': 'Altaria',
        'types': ['Dragon', 'Flying'],
      },
      444: {
        'name': 'Goomy',
        'types': ['Dragon'],
      },
      445: {
        'name': 'Sliggoo',
        'types': ['Dragon'],
      },
      446: {
        'name': 'Goodra',
        'types': ['Dragon'],
      },
      447: {
        'name': 'Regirock',
        'types': ['Rock'],
      },
      448: {
        'name': 'Regice',
        'types': ['Ice'],
      },
      449: {
        'name': 'Registeel',
        'types': ['Steel'],
      },
      450: {
        'name': 'Necrozma',
        'types': ['Psychic'],
      },
      451: {
        'name': 'Stufful',
        'types': ['Normal', 'Fighting'],
      },
      452: {
        'name': 'Bewear',
        'types': ['Normal', 'Fighting'],
      },
      453: {
        'name': 'Dhelmise',
        'types': ['Ghost', 'Grass'],
      },
      454: {
        'name': 'Mareanie',
        'types': ['Poison', 'Water'],
      },
      455: {
        'name': 'Toxapex',
        'types': ['Poison', 'Water'],
      },
      456: {
        'name': 'Hawlucha',
        'types': ['Flying', 'Fighting'],
      },
      457: {
        'name': 'Cacnea',
        'types': ['Grass'],
      },
      458: {
        'name': 'Cacturne',
        'types': ['Grass', 'Dark'],
      },
      459: {
        'name': 'Sandygast',
        'types': ['Ground', 'Ghost'],
      },
      460: {
        'name': 'Palossand',
        'types': ['Ground', 'Ghost'],
      },
      461: {
        'name': 'Amaura',
        'types': ['Rock', 'Ice'],
      },
      462: {
        'name': 'Aurorus',
        'types': ['Rock', 'Ice'],
      },
      463: {
        'name': 'Rockruff',
        'types': ['Rock'],
      },
      464: {
        'name': 'Lycanroc Midday',
        'types': ['Rock'],
      },
      465: {
        'name': 'Lycanroc Midnight',
        'types': ['Rock'],
      },
      466: {
        'name': 'Meloetta Aria',
        'types': ['Normal', 'Psychic'],
      },
      467: {
        'name': 'Meloetta Pirouette',
        'types': ['Normal', 'Fighting'],
      },
      468: {
        'name': 'Cresselia',
        'types': ['Psychic'],
      },
      469: {
        'name': 'Bruxish',
        'types': ['Water', 'Psychic'],
      },
      470: {
        'name': 'Ultra Necrozma',
        'types': ['Psychic', 'Dragon'],
      },
      471: {
        'name': 'Jangmo-o',
        'types': ['Dragon'],
      },
      472: {
        'name': 'Hakamo-o',
        'types': ['Dragon', 'Fighting'],
      },
      473: {
        'name': 'Kommo-o',
        'types': ['Dragon', 'Fighting'],
      },
      474: {
        'name': 'Wimpod',
        'types': ['Bug', 'Water'],
      },
      475: {
        'name': 'Golisopod',
        'types': ['Bug', 'Water'],
      },
      476: {
        'name': 'Fomantis',
        'types': ['Grass'],
      },
      477: {
        'name': 'Lurantis',
        'types': ['Grass'],
      },
      478: {
        'name': 'Carbink',
        'types': ['Rock', 'Fairy'],
      },
      479: {
        'name': 'Chespin',
        'types': ['Grass'],
      },
      480: {
        'name': 'Quilladin',
        'types': ['Grass'],
      },
      481: {
        'name': 'Chesnaught',
        'types': ['Grass', 'Fighting'],
      },
      482: {
        'name': 'Fennekin',
        'types': ['Fire'],
      },
      483: {
        'name': 'Braixen',
        'types': ['Fire'],
      },
      484: {
        'name': 'Delphox',
        'types': ['Psychic', 'Fire'],
      },
      485: {
        'name': 'Froakie',
        'types': ['Water'],
      },
      486: {
        'name': 'Frogadier',
        'types': ['Water'],
      },
      487: {
        'name': 'Greninja',
        'types': ['Water', 'Dark'],
      },
      488: {
        'name': 'Torkoal',
        'types': ['Fire'],
      },
      489: {
        'name': 'Pumpkaboo',
        'types': ['Ghost', 'Grass'],
      },
      490: {
        'name': 'Gourgeist',
        'types': ['Ghost', 'Grass'],
      },
      491: {
        'name': 'Swirlix',
        'types': ['Fairy'],
      },
      492: {
        'name': 'Slurpuff',
        'types': ['Fairy'],
      },
      493: {
        'name': 'Scraggy',
        'types': ['Dark', 'Fighting'],
      },
      494: {
        'name': 'Scrafty',
        'types': ['Dark', 'Fighting'],
      },
      495: {
        'name': 'Lotad',
        'types': ['Water', 'Grass'],
      },
      496: {
        'name': 'Lombre',
        'types': ['Water', 'Grass'],
      },
      497: {
        'name': 'Ludicolo',
        'types': ['Water', 'Grass'],
      },
      498: {
        'name': 'Minior',
        'types': ['Rock', 'Flying'],
      },
      499: {
        'name': 'Minior Core',
        'types': ['Rock', 'Flying'],
      },
      500: {
        'name': 'Diancie',
        'types': ['Rock', 'Fairy'],
      },
      501: {
        'name': 'Luvdisc',
        'types': ['Water'],
      }
    };

    pokemonDatabase.forEach((number, data) {
      final pokemon = PokemonModel(
        pokedexNumber: number,
        name: data['name'] as String,
        types: List<String>.from(data['types'] as List),
      );
      basicPokemon.add(pokemon);
    });

    basicPokemon.sort((a, b) => a.pokedexNumber.compareTo(b.pokedexNumber));
    return basicPokemon;
  }

  /// Exposes the embedded basic Pokémon list without any filesystem access.
  ///
  /// This is intended for tooling/scripts that need to iterate over the
  /// canonical local list to pre-generate resources (e.g., base stats JSON)
  /// without depending on platform-specific services like `path_provider`.
  List<PokemonModel> getEmbeddedPokemonListForTools() {
    return _createBasicPokemonList();
  }
}
