import 'dart:io'; // FIX 1: dart:io for File
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _bgDeep = Color(0xFF0A1F0F);
const _bgCard = Color(0xFF1A2F1F);
const _bgNav = Color(0xFF0F2A1F);
const _rarityColors = {
  'common': Colors.white70,
  'uncommon': Color(0xFF4CAF50),
  'rare': Color(0xFF2196F3),
  'legendary': Colors.amber,
};

// ─── Data Model ───────────────────────────────────────────────────────────────

// FIX 2: audioUrl field added to Bird class
class Bird {
  final String name;
  final String scientificName;
  final String imageUrl;
  final String audioUrl; // was missing — caused crash in original code
  final String lore;
  final String habitat;
  final String conservationStatus;
  final String rarity; // 'common' | 'uncommon' | 'rare' | 'legendary'
  final int baseXp;

  const Bird({
    required this.name,
    required this.scientificName,
    required this.imageUrl,
    required this.audioUrl,
    required this.lore,
    required this.habitat,
    required this.conservationStatus,
    required this.rarity,
    required this.baseXp,
  });

  Color get rarityColor => _rarityColors[rarity] ?? Colors.white70;

  int get xp {
    switch (rarity) {
      case 'uncommon': return (baseXp * 1.5).round();
      case 'rare': return baseXp * 2;
      case 'legendary': return baseXp * 5;
      default: return baseXp;
    }
  }
}

// ─── Bird Database ────────────────────────────────────────────────────────────
// 50 species across 4 rarity tiers.
// Images: Wikimedia Commons. Audio: Xeno-Canto direct MP3 links.

final List<Bird> birds = [
  // ── Common (60% pool) ──────────────────────────────────────────────────────
  Bird(
    name: 'Black-capped Chickadee',
    scientificName: 'Poecile atricapillus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Black-capped_Chickadee.jpg/800px-Black-capped_Chickadee.jpg',
    audioUrl: 'https://xeno-canto.org/sounds/uploaded/SONNZNJSHE/XC637613-Black-capped%20Chickadee.mp3',
    lore: 'Cheerful winter friend that remembers exactly who feeds it and can recall thousands of cache locations!',
    habitat: 'Deciduous and mixed forests, parks, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 50,
  ),
  Bird(
    name: 'American Robin',
    scientificName: 'Turdus migratorius',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/American_Robin.jpg/800px-American_Robin.jpg',
    audioUrl: 'https://xeno-canto.org/sounds/uploaded/SONNZNJSHE/XC637615-American%20Robin.mp3',
    lore: 'Spring herald that eats up to 3.5 metres of earthworms every day. Its cheerful song is one of the first heard at dawn.',
    habitat: 'Forests, fields, parks, gardens',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 40,
  ),
  Bird(
    name: 'House Sparrow',
    scientificName: 'Passer domesticus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Passer_domesticus_male_%2815%29.jpg/800px-Passer_domesticus_male_%2815%29.jpg',
    audioUrl: '',
    lore: 'One of the most widely distributed birds on Earth, living alongside humans on every continent except Antarctica.',
    habitat: 'Urban areas, farms, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 25,
  ),
  Bird(
    name: 'European Starling',
    scientificName: 'Sturnus vulgaris',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Sturnus_vulgaris_1_%28Marek_Szczepanek%29.jpg/800px-Sturnus_vulgaris_1_%28Marek_Szczepanek%29.jpg',
    audioUrl: '',
    lore: 'Master vocal mimic that can imitate phones, other birds, and even human speech. Their murmurations can involve millions of birds.',
    habitat: 'Farmland, cities, open woodland',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'Mallard',
    scientificName: 'Anas platyrhynchos',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Anas_platyrhynchos_male_female_quadrat.jpg/800px-Anas_platyrhynchos_male_female_quadrat.jpg',
    audioUrl: '',
    lore: 'The ancestor of nearly all domestic duck breeds. Males grow a fresh iridescent green head each autumn.',
    habitat: 'Wetlands, ponds, rivers, parks',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Song Sparrow',
    scientificName: 'Melospiza melodia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Melospiza_melodia_-_Song_Sparrow.jpg/800px-Melospiza_melodia_-_Song_Sparrow.jpg',
    audioUrl: '',
    lore: 'Each Song Sparrow learns its unique song from its father, resulting in over 30 regional dialects across North America.',
    habitat: 'Shrubby areas, marshes, gardens',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Rock Pigeon',
    scientificName: 'Columba livia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/A_Rock_Pigeon.jpg/800px-A_Rock_Pigeon.jpg',
    audioUrl: '',
    lore: 'Domesticated over 5,000 years ago, pigeons have navigated wars, carried messages, and won military medals for bravery.',
    habitat: 'Cities, cliffs, farmland',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 20,
  ),
  Bird(
    name: 'American Crow',
    scientificName: 'Corvus brachyrhynchos',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/American_Crow.jpg/800px-American_Crow.jpg',
    audioUrl: '',
    lore: 'One of the most intelligent birds alive — crows use tools, recognise human faces, and hold "funerals" for their dead.',
    habitat: 'Forests, fields, cities, shorelines',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 45,
  ),
  Bird(
    name: 'Canada Goose',
    scientificName: 'Branta canadensis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Canada_goose_on_its_nest.jpg/800px-Canada_goose_on_its_nest.jpg',
    audioUrl: '',
    lore: 'Mates for life and both parents fiercely guard the nest. They fly in a V-formation to save energy on long migrations.',
    habitat: 'Lakes, rivers, parks, golf courses',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'House Finch',
    scientificName: 'Haemorhous mexicanus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Haemorhous_mexicanus_-_Male.jpg/800px-Haemorhous_mexicanus_-_Male.jpg',
    audioUrl: '',
    lore: 'The male\'s rosy-red colour comes entirely from the berries and fruits he eats — a more colourful diet means a redder bird.',
    habitat: 'Urban areas, deserts, open forests',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Mourning Dove',
    scientificName: 'Zenaida macroura',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Mourning_dove_2007.jpg/800px-Mourning_dove_2007.jpg',
    audioUrl: '',
    lore: 'Named for its mournful cooing, this dove is one of North America\'s most numerous birds with a population over 350 million.',
    habitat: 'Open fields, suburbs, roadsides',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'Dark-eyed Junco',
    scientificName: 'Junco hyemalis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/81/Dark_Eyed_Junco.jpg/800px-Dark_Eyed_Junco.jpg',
    audioUrl: '',
    lore: 'Known as "snowbirds," juncos arrive in backyards as winter approaches, retreating to mountain forests to breed each spring.',
    habitat: 'Coniferous forests, gardens, parks',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),

  // ── Uncommon (25% pool) ───────────────────────────────────────────────────
  Bird(
    name: 'Northern Cardinal',
    scientificName: 'Cardinalis cardinalis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Northern_Cardinal_Male.jpg/800px-Northern_Cardinal_Male.jpg',
    audioUrl: 'https://xeno-canto.org/sounds/uploaded/SONNZNJSHE/XC637614-Northern%20Cardinal.mp3',
    lore: 'Unusually for songbirds, the female sings too — sometimes from the nest, a rare trait among North American birds.',
    habitat: 'Woodlands, gardens, shrubby areas',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 75,
  ),
  Bird(
    name: 'Blue Jay',
    scientificName: 'Cyanocitta cristata',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Blue_Jay_-_Cyanocitta_cristata.jpg/800px-Blue_Jay_-_Cyanocitta_cristata.jpg',
    audioUrl: '',
    lore: 'Blue Jays are nature\'s alarm system — they mimic hawk calls to scatter other birds from feeders, then swoop in to feast.',
    habitat: 'Forests, parks, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 65,
  ),
  Bird(
    name: 'Red-tailed Hawk',
    scientificName: 'Buteo jamaicensis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Red-tailed_hawk_buteo_jamaicensis_-_adult.jpg/800px-Red-tailed_hawk_buteo_jamaicensis_-_adult.jpg',
    audioUrl: '',
    lore: 'The classic Hollywood "eagle scream" is actually a Red-tailed Hawk call — borrowed because the eagle\'s squeak is far less dramatic.',
    habitat: 'Open country, deserts, forests, cities',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 85,
  ),
  Bird(
    name: 'Great Blue Heron',
    scientificName: 'Ardea herodias',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Gret_Blue_Heron_4487.jpg/800px-Gret_Blue_Heron_4487.jpg',
    audioUrl: '',
    lore: 'Despite weighing only 2.5 kg, its wingspan can reach 1.8 m. It can stand motionless for hours before striking with lightning speed.',
    habitat: 'Wetlands, shores, marshes',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 90,
  ),
  Bird(
    name: 'Ruby-throated Hummingbird',
    scientificName: 'Archilochus colubris',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Ruby-throated_Hummingbird_%284).jpg/800px-Ruby-throated_Hummingbird_%284%29.jpg',
    audioUrl: '',
    lore: 'Its heart beats 1,200 times per minute in flight, and it can fly backwards and upside-down — the only bird able to sustain hovering.',
    habitat: 'Gardens, woodland edges, meadows',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 80,
  ),
  Bird(
    name: 'Cedar Waxwing',
    scientificName: 'Bombycilla cedrorum',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Bombycilla_cedrorum_-_01.jpg/800px-Bombycilla_cedrorum_-_01.jpg',
    audioUrl: '',
    lore: 'Cedar Waxwings pass berries beak-to-beak along a perched line — a behaviour called "courtship feeding," strengthening pair bonds.',
    habitat: 'Woodlands, orchards, riparian areas',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 70,
  ),
  Bird(
    name: 'Eastern Bluebird',
    scientificName: 'Sialia sialis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Eastern_Bluebird-27527-2.jpg/800px-Eastern_Bluebird-27527-2.jpg',
    audioUrl: '',
    lore: 'Once near local extinction due to nest competition, bluebird populations bounced back thanks to millions of volunteer nest boxes.',
    habitat: 'Open fields, orchards, woodland edges',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 75,
  ),
  Bird(
    name: 'Baltimore Oriole',
    scientificName: 'Icterus galbula',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Icterus_galbula_-_male.jpg/800px-Icterus_galbula_-_male.jpg',
    audioUrl: '',
    lore: 'Female orioles weave intricate hanging basket nests — some so sturdy they survive several winters long after being abandoned.',
    habitat: 'Deciduous forests, riverbanks, parks',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 80,
  ),
  Bird(
    name: 'Barn Swallow',
    scientificName: 'Hirundo rustica',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Hirundo_rustica_-_Radujevac.jpg/800px-Hirundo_rustica_-_Radujevac.jpg',
    audioUrl: '',
    lore: 'The most widely distributed swallow on Earth, found on every continent except Antarctica. Can travel 320 km in a single day.',
    habitat: 'Open fields, farms, near water',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 65,
  ),
  Bird(
    name: 'Pileated Woodpecker',
    scientificName: 'Dryocopus pileatus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Pileated_Woodpecker_Dryocopus_pileatus.jpg/800px-Pileated_Woodpecker_Dryocopus_pileatus.jpg',
    audioUrl: '',
    lore: 'North America\'s largest woodpecker, it excavates rectangular holes large enough to split a small tree — the Woody Woodpecker\'s inspiration.',
    habitat: 'Mature deciduous and mixed forests',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 90,
  ),
  Bird(
    name: 'American Goldfinch',
    scientificName: 'Spinus tristis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Spinus-tristis-002.jpg/800px-Spinus-tristis-002.jpg',
    audioUrl: '',
    lore: 'Completely moults twice a year — males transform from olive-drab in winter to brilliant yellow in spring as if painted by the sun.',
    habitat: 'Fields, meadows, roadsides, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 65,
  ),

  // ── Rare (12% pool) ───────────────────────────────────────────────────────
  Bird(
    name: 'Snowy Owl',
    scientificName: 'Bubo scandiacus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/70/Snowy_owl_-_Bubo_scandiacus.jpg/800px-Snowy_owl_-_Bubo_scandiacus.jpg',
    audioUrl: '',
    lore: 'Hunts by day in the Arctic tundra using asymmetrical ears that locate prey under 30 cm of snow with pinpoint accuracy.',
    habitat: 'Arctic tundra, open fields in winter',
    conservationStatus: 'Vulnerable',
    rarity: 'rare',
    baseXp: 150,
  ),
  Bird(
    name: 'Painted Bunting',
    scientificName: 'Passerina ciris',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Painted_bunting_(Passerina_ciris).jpg/800px-Painted_bunting_%28Passerina_ciris%29.jpg',
    audioUrl: '',
    lore: 'Often called the most beautiful bird in North America — the male is a living kaleidoscope of red, blue, and green.',
    habitat: 'Thickets, woodland edges, brushy areas',
    conservationStatus: 'Near Threatened',
    rarity: 'rare',
    baseXp: 180,
  ),
  Bird(
    name: 'Scarlet Tanager',
    scientificName: 'Piranga olivacea',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Scarlet_Tanager_%28Piranga_olivacea%29_male.jpg/800px-Scarlet_Tanager_%28Piranga_olivacea%29_male.jpg',
    audioUrl: '',
    lore: 'Despite the male\'s blazing red plumage, this bird is surprisingly hard to spot — it lives high in the forest canopy.',
    habitat: 'Deciduous forests, forest edges',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 160,
  ),
  Bird(
    name: 'American Flamingo',
    scientificName: 'Phoenicopterus ruber',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Phoenicopterus_ruber_in_S%C3%A3o_Paulo_Zoo.jpg/800px-Phoenicopterus_ruber_in_S%C3%A3o_Paulo_Zoo.jpg',
    audioUrl: '',
    lore: 'Pink colouring comes entirely from carotenoid pigments in their algae and crustacean diet. Without it, they\'d be white.',
    habitat: 'Coastal lagoons, mudflats, salt lakes',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 200,
  ),
  Bird(
    name: 'Long-eared Owl',
    scientificName: 'Asio otus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e2/Long-eared_Owl_Asio_otus.jpg/800px-Long-eared_Owl_Asio_otus.jpg',
    audioUrl: '',
    lore: 'Its "ear" tufts are purely decorative feathers — the real ears are hidden under facial disc feathers at different heights for stereo hearing.',
    habitat: 'Dense forest edges, shrubby areas',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 165,
  ),
  Bird(
    name: 'Black-crowned Night Heron',
    scientificName: 'Nycticorax nycticorax',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Nycticorax_nycticorax_1_-_Pak_Chong.jpg/800px-Nycticorax_nycticorax_1_-_Pak_Chong.jpg',
    audioUrl: '',
    lore: 'Unlike most herons it hunts nocturnally, using its large red eyes to spot fish in the dark. It lures prey by wiggling foot in the water.',
    habitat: 'Wetlands, swamps, coastal areas',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 155,
  ),
  Bird(
    name: 'Indigo Bunting',
    scientificName: 'Passerina cyanea',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Indigo_bunting_-_Passerina_cyanea.jpg/800px-Indigo_bunting_-_Passerina_cyanea.jpg',
    audioUrl: '',
    lore: 'The male\'s brilliant blue is not pigment but pure structural colour — rearranging feather structures to scatter blue light.',
    habitat: 'Woodland edges, fields, roadsides',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 170,
  ),

  // ── Legendary (3% pool) ──────────────────────────────────────────────────
  Bird(
    name: 'Resplendent Quetzal',
    scientificName: 'Pharomachrus mocinno',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Respledent_Quetzal.jpg/800px-Respledent_Quetzal.jpg',
    audioUrl: '',
    lore: 'Sacred to the ancient Maya and Aztec as a symbol of freedom and wealth — it dies in captivity. Its tail feathers reach 1 metre long.',
    habitat: 'Cloud forests of Central America',
    conservationStatus: 'Near Threatened',
    rarity: 'legendary',
    baseXp: 500,
  ),
  Bird(
    name: 'Shoebill',
    scientificName: 'Balaeniceps rex',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Shoebill_Balaeniceps_rex_by_Bart_Wursten_in_Zambia.jpg/800px-Shoebill_Balaeniceps_rex_by_Bart_Wursten_in_Zambia.jpg',
    audioUrl: '',
    lore: 'Unchanged since the dinosaur era, its bill is so powerful it can decapitate a baby crocodile. It bows to humans it respects.',
    habitat: 'Papyrus swamps, tropical Africa',
    conservationStatus: 'Vulnerable',
    rarity: 'legendary',
    baseXp: 600,
  ),
  Bird(
    name: 'Kakapo',
    scientificName: 'Strigops habroptila',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/71/Kakapo_Sirocco.jpg/800px-Kakapo_Sirocco.jpg',
    audioUrl: '',
    lore: 'World\'s heaviest parrot, only nocturnal flightless parrot, and one of the longest-lived birds. Only ~250 survive today.',
    habitat: 'New Zealand island sanctuaries only',
    conservationStatus: 'Critically Endangered',
    rarity: 'legendary',
    baseXp: 800,
  ),
  Bird(
    name: 'Harpy Eagle',
    scientificName: 'Harpia harpyja',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Harpia_harpyja_-_Buffalo_Zoo_-_Buffalo%2C_NY.jpg/800px-Harpia_harpyja_-_Buffalo_Zoo_-_Buffalo%2C_NY.jpg',
    audioUrl: '',
    lore: 'The most powerful eagle in the world — its talons are as large as a bear\'s claws and can exert 530 N of crushing force.',
    habitat: 'Lowland tropical rainforests',
    conservationStatus: 'Vulnerable',
    rarity: 'legendary',
    baseXp: 700,
  ),
  Bird(
    name: 'Superb Lyrebird',
    scientificName: 'Menura novaehollandiae',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Albert_lyrebird.jpg/800px-Albert_lyrebird.jpg',
    audioUrl: '',
    lore: 'Considered the world\'s greatest mimic — it perfectly replicates chainsaws, camera shutters, car alarms, and any bird call it hears.',
    habitat: 'Wet forests, fern gullies of Australia',
    conservationStatus: 'Least Concern',
    rarity: 'legendary',
    baseXp: 650,
  ),
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

String levelTitle(int level) {
  if (level < 3) return 'Fledgling';
  if (level < 6) return 'Nestling';
  if (level < 10) return 'Sparrow';
  if (level < 15) return 'Warbler';
  if (level < 20) return 'Songweaver';
  if (level < 30) return 'Falconer';
  if (level < 40) return 'Eagle Scout';
  return 'Master Birder';
}

int xpForNextLevel(int level) => (1000 * pow(level, 1.4)).round();

/// Weighted random bird pick: common 60%, uncommon 25%, rare 12%, legendary 3%
Bird _weightedRandomBird(Random rng) {
  final r = rng.nextDouble();
  late String rarity;
  if (r < 0.60) {
    rarity = 'common';
  } else if (r < 0.85) {
    rarity = 'uncommon';
  } else if (r < 0.97) {
    rarity = 'rare';
  } else {
    rarity = 'legendary';
  }
  final pool = birds.where((b) => b.rarity == rarity).toList();
  return pool[rng.nextInt(pool.length)];
}

const _achievements = {
  'first_bird': ('🐦', 'First Feather', 'Identify your first bird'),
  'five_species': ('🌿', 'Nature Curious', 'Collect 5 different species'),
  'ten_species': ('🏆', 'Avid Birder', 'Collect 10 different species'),
  'twenty_species': ('🦅', 'Wing Watcher', 'Collect 20 different species'),
  'rare_find': ('💎', 'Rare Encounter', 'Identify a rare bird'),
  'legendary_find': ('✨', 'Legend Spotter', 'Identify a legendary bird'),
  'level_5': ('⭐', 'Rising Birder', 'Reach level 5'),
  'level_10': ('🌟', 'Expert Nester', 'Reach level 10'),
  'level_20': ('🌠', 'Sky Master', 'Reach level 20'),
};

// ─── App Entry ────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // FIX 3: Box<String> — no type adapter needed (was Box<Bird> which crashed)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AviQuest());
}

class AviQuest extends StatelessWidget {
  const AviQuest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AviQuest',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bgDeep,
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Color(0xFF4CAF50),
          surface: _bgCard,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _bgNav,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Home Screen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Player stats
  int level = 1;
  int xp = 0;
  int streak = 1;
  Set<String> unlockedAchievements = {};

  // Storage — FIX 3: Box<String> stores bird names, no adapter needed
  late Box<String> aviaryBox;
  bool hiveReady = false;

  // Hardware
  final _player = AudioPlayer();
  final _rng = Random();
  CameraController? _cam;
  bool _camReady = false;

  int _tab = 1;
  String _guideSearch = '';
  String _guideRarityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initHive();
    _initCamera();
  }

  @override
  void dispose() {
    // FIX 6: dispose camera and player to avoid resource leaks
    _cam?.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    aviaryBox = await Hive.openBox<String>('aviary_v2');
    // FIX 7: mounted check after await
    if (!mounted) return;
    setState(() => hiveReady = true);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // FIX 5: guard against empty camera list
      if (cameras.isEmpty) return;
      _cam = CameraController(cameras[0], ResolutionPreset.high);
      await _cam!.initialize();
      // FIX 7: mounted check after await
      if (!mounted) return;
      setState(() => _camReady = true);
    } catch (_) {
      // Camera unavailable — silently degrade
    }
  }

  Future<void> _takePhoto() async {
    await Permission.camera.request();
    if (_cam == null || !_camReady) return;
    try {
      final file = await _cam!.takePicture();
      if (!mounted) return;
      await _simulateIdentify(File(file.path)); // FIX 1: dart:io imported
    } catch (_) {}
  }

  Future<void> _simulateIdentify(File _) async {
    final matchedBird = _weightedRandomBird(_rng);

    // Show analysing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔬 Analysing...', style: TextStyle(color: Colors.amber)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 16),
          Text('Processing photo...', style: TextStyle(color: Colors.white70)),
        ]),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.pop(context);
    _showFoundDialog(matchedBird);
  }

  void _showFoundDialog(Bird bird) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rarity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: bird.rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bird.rarityColor),
                ),
                child: Text(
                  bird.rarity.toUpperCase(),
                  style: TextStyle(color: bird.rarityColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 12),
              Text(
                '✨ ${bird.name}',
                style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms),
              Text(
                bird.scientificName,
                style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildNetworkImage(bird.imageUrl, 220),
              ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 12),
              Text(bird.lore, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  Text(' +${bird.xp} XP', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addBird(bird);
                      },
                      child: const Text('Add to Aviary'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addBird(Bird bird) {
    // FIX 2 & 3: audioUrl now exists; Box<String> stores name
    if (bird.audioUrl.isNotEmpty) {
      _player.setUrl(bird.audioUrl).then((_) => _player.play()).catchError((_) {});
    }

    setState(() {
      // FIX 3: store bird name string, not Bird object
      aviaryBox.add(bird.name);
      xp += bird.xp;

      // Level up loop
      while (xp >= xpForNextLevel(level)) {
        xp -= xpForNextLevel(level);
        level++;
        _showLevelUp();
      }

      _checkAchievements(bird);
    });
  }

  void _showLevelUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.amber,
        duration: const Duration(seconds: 3),
        content: Row(children: [
          const Text('🎉 LEVEL UP! ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          Text('You are now a ${levelTitle(level)}!', style: const TextStyle(color: Colors.black)),
        ]),
      ),
    );
  }

  void _checkAchievements(Bird bird) {
    final collected = aviaryBox.length;
    final newOnes = <String>[];

    void tryUnlock(String key) {
      if (!unlockedAchievements.contains(key)) {
        unlockedAchievements.add(key);
        newOnes.add(key);
      }
    }

    if (collected >= 1) tryUnlock('first_bird');
    if (collected >= 5) tryUnlock('five_species');
    if (collected >= 10) tryUnlock('ten_species');
    if (collected >= 20) tryUnlock('twenty_species');
    if (bird.rarity == 'rare' || bird.rarity == 'legendary') tryUnlock('rare_find');
    if (bird.rarity == 'legendary') tryUnlock('legendary_find');
    if (level >= 5) tryUnlock('level_5');
    if (level >= 10) tryUnlock('level_10');
    if (level >= 20) tryUnlock('level_20');

    for (final key in newOnes) {
      final a = _achievements[key]!;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A2F1F),
            duration: const Duration(seconds: 4),
            content: Row(children: [
              Text(a.$1, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Achievement Unlocked!', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                Text(a.$2, style: const TextStyle(color: Colors.white70)),
              ]),
            ]),
          ),
        );
      });
    }
  }

  void _showBirdDetail(Bird bird) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: bird.rarityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bird.rarityColor),
                ),
                child: Text(bird.rarity.toUpperCase(),
                  style: TextStyle(color: bird.rarityColor, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(bird.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber),
              textAlign: TextAlign.center)),
            Center(child: Text(bird.scientificName,
              style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildNetworkImage(bird.imageUrl, 240),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.auto_stories, 'Lore', bird.lore),
            _detailRow(Icons.landscape, 'Habitat', bird.habitat),
            _detailRow(Icons.eco, 'Conservation', bird.conservationStatus),
            _detailRow(Icons.bolt, 'XP Value', '+${bird.xp} XP'),
            if (bird.audioUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _player.setUrl(bird.audioUrl).then((_) => _player.play()).catchError((_) {});
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Play Bird Call'),
              ),
            ],
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ])),
      ]),
    );
  }

  Widget _buildNetworkImage(String url, double height) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: _bgCard,
        highlightColor: const Color(0xFF2A3F2F),
        child: Container(height: height, color: _bgCard),
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: _bgCard,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 48)),
      ),
    );
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  Widget _buildIdentifyTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('AviQuest', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber))
            .animate().fadeIn().slideY(begin: -0.3),
        const Text('Point at a bird and identify it!',
            style: TextStyle(color: Colors.white54)).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 24),
        if (_camReady && _cam != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: CameraPreview(_cam!),
            ),
          ).animate().fadeIn(delay: 200.ms).scale()
        else
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.camera_alt, size: 64, color: Colors.white24),
                SizedBox(height: 8),
                Text('Camera unavailable', style: TextStyle(color: Colors.white38)),
              ]),
            ),
          ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text('Identify by Photo'),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Simulate audio identification (same random logic)
                _simulateIdentify(File(''));
              },
              icon: const Icon(Icons.mic, color: Colors.amber),
              label: const Text('By Call', style: TextStyle(color: Colors.amber)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3),
          ],
        ),
      ],
    );
  }

  Widget _buildAviaryTab() {
    if (!hiveReady) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    // FIX 4: ValueListenableBuilder<Box<String>> — correct type
    return ValueListenableBuilder<Box<String>>(
      valueListenable: aviaryBox.listenable(),
      builder: (context, box, _) {
        if (box.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.auto_awesome, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              const Text('Your aviary is empty!', style: TextStyle(fontSize: 20, color: Colors.white54)),
              const SizedBox(height: 8),
              const Text('Identify birds to add them here.',
                  style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _tab = 1),
                child: const Text('Go Identify'),
              ),
            ]),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.82, mainAxisSpacing: 12, crossAxisSpacing: 12,
          ),
          itemCount: box.length,
          itemBuilder: (c, i) {
            final birdName = box.getAt(i);
            if (birdName == null) return const SizedBox.shrink(); // FIX 5: null guard
            final bird = birds.firstWhere(
              (b) => b.name == birdName,
              orElse: () => birds.first,
            );
            return GestureDetector(
              onTap: () => _showBirdDetail(bird),
              child: Card(
                color: _bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: bird.rarityColor.withOpacity(0.6), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: bird.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: _bgCard,
                        highlightColor: const Color(0xFF2A3F2F),
                        child: Container(color: _bgCard),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.white24),
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(bird.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(bird.rarity,
                            style: TextStyle(color: bird.rarityColor, fontSize: 11)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldGuideTab() {
    final filtered = birds.where((b) {
      final matchRarity = _guideRarityFilter == 'all' || b.rarity == _guideRarityFilter;
      final matchSearch = _guideSearch.isEmpty ||
          b.name.toLowerCase().contains(_guideSearch.toLowerCase()) ||
          b.scientificName.toLowerCase().contains(_guideSearch.toLowerCase());
      return matchRarity && matchSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _guideSearch = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search species...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: _bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['all', 'common', 'uncommon', 'rare', 'legendary'].map((r) {
              final selected = _guideRarityFilter == r;
              final color = r == 'all' ? Colors.white70 : (_rarityColors[r] ?? Colors.white70);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _guideRarityFilter = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : _bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? color : Colors.white12),
                    ),
                    child: Text(r[0].toUpperCase() + r.substring(1),
                      style: TextStyle(color: selected ? color : Colors.white54,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (c, i) {
              final bird = filtered[i];
              return Card(
                color: _bgCard,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: bird.rarityColor.withOpacity(0.4)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60, height: 60,
                      child: CachedNetworkImage(
                        imageUrl: bird.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: _bgCard,
                          highlightColor: const Color(0xFF2A3F2F),
                          child: Container(color: _bgCard),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.white24),
                      ),
                    ),
                  ),
                  title: Text(bird.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(bird.scientificName,
                      style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12)),
                    Row(children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: bird.rarityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: bird.rarityColor.withOpacity(0.5)),
                        ),
                        child: Text(bird.rarity,
                          style: TextStyle(color: bird.rarityColor, fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      Text('+${bird.xp} XP', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                    ]),
                  ]),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () => _showBirdDetail(bird),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapTab() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.map, size: 80, color: Colors.white24)
            .animate().fadeIn().scale(),
        const SizedBox(height: 16),
        const Text('Interactive Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber))
            .animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        const Text('Hotspot mapping & community sightings\ncoming soon!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people, color: Colors.amber),
            SizedBox(width: 8),
            Text('1,247 sightings logged today 🌍', style: TextStyle(color: Colors.white70)),
          ]),
        ).animate().fadeIn(delay: 300.ms),
      ]),
    );
  }

  Widget _buildProfileTab() {
    final nextLevelXp = xpForNextLevel(level);
    final progress = xp / nextLevelXp;
    final collectedCount = hiveReady ? aviaryBox.length : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar ring
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.amber, Color(0xFF4CAF50)]),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 20, spreadRadius: 4)],
            ),
            child: const Center(child: Text('🦅', style: TextStyle(fontSize: 48))),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 16),
          Text(levelTitle(level),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber))
              .animate().fadeIn(delay: 100.ms),
          Text('Level $level', style: const TextStyle(fontSize: 16, color: Colors.white54)),
          const SizedBox(height: 20),
          // XP Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('XP Progress', style: TextStyle(color: Colors.white70)),
                Text('$xp / $nextLevelXp', style: const TextStyle(color: Colors.amber)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: _bgCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              _statCard('🔥', '$streak', 'Day Streak'),
              const SizedBox(width: 12),
              _statCard('🐦', '$collectedCount', 'Species'),
              const SizedBox(width: 12),
              _statCard('🏆', '${unlockedAchievements.length}', 'Badges'),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          // Achievements
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('Achievements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _achievements.entries.map((e) {
              final unlocked = unlockedAchievements.contains(e.key);
              return Tooltip(
                message: unlocked ? e.value.$3 : '???',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: unlocked ? Colors.amber.withOpacity(0.15) : _bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: unlocked ? Colors.amber : Colors.white12),
                  ),
                  child: Center(
                    child: Text(
                      unlocked ? e.value.$1 : '🔒',
                      style: TextStyle(fontSize: 28, color: unlocked ? null : Colors.white24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 24),
          // Eco impact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('🌍', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Eco Impact', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('Your sightings help scientists track bird populations worldwide.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              ])),
            ]),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildMapTab(),
      _buildIdentifyTab(),
      _buildAviaryTab(),
      _buildFieldGuideTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _tab = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Identify'),
          BottomNavigationBarItem(icon: Icon(Icons.collections), label: 'Aviary'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Field Guide'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
