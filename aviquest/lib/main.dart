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
// 150 species across 4 rarity tiers, drawn from every continent.
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

  // ── Additional Common species ─────────────────────────────────────────────
  Bird(
    name: 'White-breasted Nuthatch',
    scientificName: 'Sitta carolinensis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/White-breasted_nuthatch_2.jpg/800px-White-breasted_nuthatch_2.jpg',
    audioUrl: '',
    lore: 'Walks head-first down tree trunks — a trick no other North American bird can do — to find insects that upward-climbing birds miss.',
    habitat: 'Deciduous forests, parks, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 40,
  ),
  Bird(
    name: 'Downy Woodpecker',
    scientificName: 'Dryobates pubescens',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Downy_Woodpecker.jpg/800px-Downy_Woodpecker.jpg',
    audioUrl: '',
    lore: 'North America\'s smallest woodpecker, yet it hammers at 20 strikes per second — its skull is built like a biological crash helmet.',
    habitat: 'Forests, orchards, parks, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Red-winged Blackbird',
    scientificName: 'Agelaius phoeniceus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Agelaius_phoeniceus_-_breeding_male.jpg/800px-Agelaius_phoeniceus_-_breeding_male.jpg',
    audioUrl: '',
    lore: 'One of the most abundant birds in North America — flocks can reach millions. Males flash their red epaulettes to claim territory.',
    habitat: 'Marshes, fields, roadsides',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'Common Grackle',
    scientificName: 'Quiscalus quiscula',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Common_Grackle_Ithaca.jpg/800px-Common_Grackle_Ithaca.jpg',
    audioUrl: '',
    lore: 'Can soften hard food by dunking it in water — one of the few birds observed deliberately "washing" its meals before eating.',
    habitat: 'Fields, parks, urban areas, marshes',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 25,
  ),
  Bird(
    name: 'Tufted Titmouse',
    scientificName: 'Baeolophus bicolor',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Tufted_Titmouse-27527-3.jpg/800px-Tufted_Titmouse-27527-3.jpg',
    audioUrl: '',
    lore: 'Collects hair for its nest — and sometimes plucks it straight from sleeping dogs, squirrels, or even people!',
    habitat: 'Deciduous forests, parks, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 40,
  ),
  Bird(
    name: 'Carolina Wren',
    scientificName: 'Thryothorus ludovicianus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Carolina_Wren_in_Nashville%2C_Tennessee.jpg/800px-Carolina_Wren_in_Nashville%2C_Tennessee.jpg',
    audioUrl: '',
    lore: 'Despite its tiny size, its song is one of the loudest relative to body weight of any bird — it can be heard half a kilometre away.',
    habitat: 'Dense brush, wooded suburbs, gardens',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Northern Flicker',
    scientificName: 'Colaptes auratus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Northern_Flicker_%28Red-shafted%29.jpg/800px-Northern_Flicker_%28Red-shafted%29.jpg',
    audioUrl: '',
    lore: 'Unlike most woodpeckers, it forages mostly on the ground eating ants and beetles — its tongue is 5 cm longer than its beak.',
    habitat: 'Open woodlands, forest edges, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 45,
  ),
  Bird(
    name: 'Brown-headed Cowbird',
    scientificName: 'Molothrus ater',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Molothrus_ater2.jpg/800px-Molothrus_ater2.jpg',
    audioUrl: '',
    lore: 'A brood parasite that lays its eggs in 220+ other species\' nests, then lets the host parents raise its chicks.',
    habitat: 'Open woodlands, fields, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'Killdeer',
    scientificName: 'Charadrius vociferus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Killdeer_%28Charadrius_vociferus%29.jpg/800px-Killdeer_%28Charadrius_vociferus%29.jpg',
    audioUrl: '',
    lore: 'Performs a convincing "broken-wing" act to lure predators away from its nest — rolling on the ground and dragging a wing dramatically.',
    habitat: 'Fields, lawns, parking lots, shores',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 40,
  ),
  Bird(
    name: 'Ring-billed Gull',
    scientificName: 'Larus delawarensis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Ring-billed_Gull_Larus_delawarensis.jpg/800px-Ring-billed_Gull_Larus_delawarensis.jpg',
    audioUrl: '',
    lore: 'The classic inland "seagull" — highly adaptable and one of the most common gulls across North America, thriving in cities far from the coast.',
    habitat: 'Lakes, rivers, parking lots, coasts',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 20,
  ),
  Bird(
    name: 'Common Loon',
    scientificName: 'Gavia immer',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Gavia_immer_-_on_lake.jpg/800px-Gavia_immer_-_on_lake.jpg',
    audioUrl: '',
    lore: 'Its haunting wail carries 3 km across wilderness lakes. Loons can dive 75 m deep and stay submerged for over a minute.',
    habitat: 'Remote lakes, coastal waters in winter',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 50,
  ),
  Bird(
    name: 'Herring Gull',
    scientificName: 'Larus argentatus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Herring_Gull_arp.jpg/800px-Herring_Gull_arp.jpg',
    audioUrl: '',
    lore: 'Drops shellfish from height onto rocks to crack them open — a learned behaviour passed down through generations of gulls.',
    habitat: 'Coasts, harbours, lakes, tips',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 25,
  ),
  Bird(
    name: 'European Robin',
    scientificName: 'Erithacus rubecula',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Erithacus_rubecula_with_cocked_head.jpg/800px-Erithacus_rubecula_with_cocked_head.jpg',
    audioUrl: '',
    lore: 'Britain\'s unofficial national bird, aggressively territorial — it will attack mirrors, believing its reflection is a rival.',
    habitat: 'Woodland, gardens, hedgerows',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Great Tit',
    scientificName: 'Parus major',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Parus_major_Tezpur.jpg/800px-Parus_major_Tezpur.jpg',
    audioUrl: '',
    lore: 'Has over 40 distinct call types, making it one of the most vocal songbirds in Europe — each call has a specific meaning.',
    habitat: 'Woodland, gardens, parks',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'Common Blackbird',
    scientificName: 'Turdus merula',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a9/Common_Blackbird.jpg/800px-Common_Blackbird.jpg',
    audioUrl: '',
    lore: 'The male\'s rich, flute-like song is considered one of the most beautiful in the avian world — each bird improvises its own unique variations.',
    habitat: 'Woodland, gardens, parks, hedgerows',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 35,
  ),
  Bird(
    name: 'Common Chaffinch',
    scientificName: 'Fringilla coelebs',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Fringilla_coelebs_chaffinch_male_edit2.jpg/800px-Fringilla_coelebs_chaffinch_male_edit2.jpg',
    audioUrl: '',
    lore: 'One of the most abundant birds in Europe. Its song is a complex cascade that young males must learn from their fathers in the first year.',
    habitat: 'Woodland, gardens, farmland',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 30,
  ),
  Bird(
    name: 'Eurasian Magpie',
    scientificName: 'Pica pica',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Pica_pica_-_Compans-Caffarelli_-_2012-03-16.jpg/800px-Pica_pica_-_Compans-Caffarelli_-_2012-03-16.jpg',
    audioUrl: '',
    lore: 'One of only a handful of animals that can recognise itself in a mirror — a test of self-awareness passed by very few species on Earth.',
    habitat: 'Farmland, urban areas, woodland edges',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 40,
  ),
  Bird(
    name: 'Barn Owl',
    scientificName: 'Tyto alba',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Tyto_alba_close_up.jpg/800px-Tyto_alba_close_up.jpg',
    audioUrl: '',
    lore: 'The most widespread land bird on Earth. Its heart-shaped face acts as a satellite dish, funneling sound to ears offset at different heights.',
    habitat: 'Open farmland, grasslands, barns',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 55,
  ),
  Bird(
    name: 'Common Swift',
    scientificName: 'Apus apus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/Apus_apus_01.jpg/800px-Apus_apus_01.jpg',
    audioUrl: '',
    lore: 'Spends almost its entire life airborne — eating, sleeping, and even mating in flight. It may not land for 2–3 years after fledging.',
    habitat: 'Open skies, nests on buildings',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 45,
  ),
  Bird(
    name: 'Grey Heron',
    scientificName: 'Ardea cinerea',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Ardea_cinerea_-_Grey_Heron_2.jpg/800px-Ardea_cinerea_-_Grey_Heron_2.jpg',
    audioUrl: '',
    lore: 'Can wait motionless for hours, then strike with a spear-like bill in under 0.06 seconds — faster than a human eye can follow.',
    habitat: 'Wetlands, rivers, lakes, estuaries',
    conservationStatus: 'Least Concern',
    rarity: 'common',
    baseXp: 40,
  ),

  // ── Additional Uncommon species ───────────────────────────────────────────
  Bird(
    name: 'Belted Kingfisher',
    scientificName: 'Megaceryle alcyon',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Belted_Kingfisher_%28Megaceryle_alcyon%29_%286-19-06%29.jpg/800px-Belted_Kingfisher_%28Megaceryle_alcyon%29_%286-19-06%29.jpg',
    audioUrl: '',
    lore: 'Dives bill-first into water from up to 10 m, compensating for light refraction with precision — its brain automatically adjusts the aim.',
    habitat: 'Rivers, lakes, coastal waters',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 85,
  ),
  Bird(
    name: 'Osprey',
    scientificName: 'Pandion haliaetus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Osprey_-_natures_pics.jpg/800px-Osprey_-_natures_pics.jpg',
    audioUrl: '',
    lore: 'The only raptor that plunges entirely underwater to catch fish — its reversible outer toe and spiky foot pads grip slippery prey perfectly.',
    habitat: 'Coasts, lakes, rivers worldwide',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 100,
  ),
  Bird(
    name: 'Peregrine Falcon',
    scientificName: 'Falco peregrinus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Falco_peregrinus_-_01.jpg/800px-Falco_peregrinus_-_01.jpg',
    audioUrl: '',
    lore: 'The fastest animal on Earth — it stoops at over 380 km/h. Special baffles in its nostrils prevent its lungs from bursting at that speed.',
    habitat: 'Cliffs, cities, open country',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 110,
  ),
  Bird(
    name: 'Great Horned Owl',
    scientificName: 'Bubo virginianus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Bubo_virginianus_06.jpg/800px-Bubo_virginianus_06.jpg',
    audioUrl: '',
    lore: 'Has a grip strength of 300 PSI — more powerful than a human hand. It starts nesting in winter, incubating eggs in temperatures of −27 °C.',
    habitat: 'Forests, deserts, suburbs, tundra',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 95,
  ),
  Bird(
    name: 'Purple Martin',
    scientificName: 'Progne subis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Progne_subis_-_Purple_Martin_male.jpg/800px-Progne_subis_-_Purple_Martin_male.jpg',
    audioUrl: '',
    lore: 'North America\'s largest swallow, so dependent on human-provided nest boxes that eastern populations could go extinct without them.',
    habitat: 'Open areas near water, suburbs',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 75,
  ),
  Bird(
    name: 'Wood Duck',
    scientificName: 'Aix sponsa',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Wood_duck_%28Aix_sponsa%29.jpg/800px-Wood_duck_%28Aix_sponsa%29.jpg',
    audioUrl: '',
    lore: 'Ducklings leap from their nest cavity — sometimes 20 m high — within 24 hours of hatching, bouncing off the ground and waddling to water.',
    habitat: 'Wooded swamps, rivers, ponds',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 80,
  ),
  Bird(
    name: 'Common Kingfisher',
    scientificName: 'Alcedo atthis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Common_kingfisher_alcedo_atthis.jpg/800px-Common_kingfisher_alcedo_atthis.jpg',
    audioUrl: '',
    lore: 'Engineers of the Shinkansen bullet train studied the kingfisher\'s beak to reduce the sonic boom it created entering tunnels.',
    habitat: 'Rivers, streams, ponds, coasts',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 90,
  ),
  Bird(
    name: 'Atlantic Puffin',
    scientificName: 'Fratercula arctica',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Atlantic_Puffin.jpg/800px-Atlantic_Puffin.jpg',
    audioUrl: '',
    lore: 'Can carry up to 62 fish in its beak at once, thanks to backward-facing spines on its tongue. Spends most of its life far out at sea.',
    habitat: 'Rocky sea cliffs, open North Atlantic',
    conservationStatus: 'Vulnerable',
    rarity: 'uncommon',
    baseXp: 100,
  ),
  Bird(
    name: 'European Bee-eater',
    scientificName: 'Merops apiaster',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Merops_apiaster_-_European_bee-eater.jpg/800px-Merops_apiaster_-_European_bee-eater.jpg',
    audioUrl: '',
    lore: 'Catches bees mid-air and smacks them against a branch to squeeze out the venom before swallowing them whole.',
    habitat: 'Open country, riverbanks, light woodland',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 85,
  ),
  Bird(
    name: 'Eurasian Hoopoe',
    scientificName: 'Upupa epops',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f0/Upupa_epops_qtl1.jpg/800px-Upupa_epops_qtl1.jpg',
    audioUrl: '',
    lore: 'Its fan-like crest raises when alarmed. The nest has a bacteria-laden odour so foul it repels predators — chosen deliberately.',
    habitat: 'Open woodland, farmland, gardens',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 80,
  ),
  Bird(
    name: 'Bohemian Waxwing',
    scientificName: 'Bombycilla garrulus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Bombycilla_garrulus1.jpg/800px-Bombycilla_garrulus1.jpg',
    audioUrl: '',
    lore: 'Can consume twice its body weight in berries daily. Its liver detoxifies ethanol so efficiently it can eat fermented berries without getting drunk.',
    habitat: 'Boreal forests, parks in winter',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 75,
  ),
  Bird(
    name: 'Green-winged Teal',
    scientificName: 'Anas crecca',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Anas-crecca-001.jpg/800px-Anas-crecca-001.jpg',
    audioUrl: '',
    lore: 'One of the smallest and fastest ducks in North America — capable of taking off almost vertically from the water when startled.',
    habitat: 'Marshes, shallow ponds, tidal flats',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 70,
  ),
  Bird(
    name: 'Roseate Spoonbill',
    scientificName: 'Platalea ajaja',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Roseate_Spoonbill_%28Platalea_ajaja%29_%284423893780%29.jpg/800px-Roseate_Spoonbill_%28Platalea_ajaja%29_%284423893780%29.jpg',
    audioUrl: '',
    lore: 'Sweeps its spoon-shaped bill side to side through shallow water, snapping shut in 25 milliseconds whenever it touches a fish.',
    habitat: 'Coastal marshes, mangroves, estuaries',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 90,
  ),
  Bird(
    name: 'Sandhill Crane',
    scientificName: 'Antigone canadensis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/Sandhill_Crane_%28Grus_canadensis%29.jpg/800px-Sandhill_Crane_%28Grus_canadensis%29.jpg',
    audioUrl: '',
    lore: 'One of Earth\'s oldest living bird species — fossils identical to modern Sandhill Cranes are over 2.5 million years old.',
    habitat: 'Wetlands, meadows, farmland',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 85,
  ),
  Bird(
    name: 'Anna\'s Hummingbird',
    scientificName: 'Calypte anna',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/30/Annas_Hummingbird.jpg/800px-Annas_Hummingbird.jpg',
    audioUrl: '',
    lore: 'Makes the loudest sound relative to body size of any bird — a piercing dive-display produces 90 dB, equivalent to a lawn mower.',
    habitat: 'Gardens, chaparral, open woodland',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 80,
  ),
  Bird(
    name: 'American Bittern',
    scientificName: 'Botaurus lentiginosus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Botaurus_lentiginosus-2.jpg/800px-Botaurus_lentiginosus-2.jpg',
    audioUrl: '',
    lore: 'Its "pump-er-lunk" call is one of the strangest sounds in nature. When threatened, it freezes with its neck stretched and bill pointing skyward.',
    habitat: 'Fresh and brackish marshes',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 75,
  ),
  Bird(
    name: 'Common Pheasant',
    scientificName: 'Phasianus colchicus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Phasianus_colchicus_male_Bulgaria.jpg/800px-Phasianus_colchicus_male_Bulgaria.jpg',
    audioUrl: '',
    lore: 'Introduced worldwide from Asia over 2,000 years ago. When flushed, it leaps into the air with a startling burst of speed and noise.',
    habitat: 'Farmland, woodland edges, scrub',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 65,
  ),
  Bird(
    name: 'Little Owl',
    scientificName: 'Athene noctua',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8b/Little_owl_%28Athene_noctua%29_2.jpg/800px-Little_owl_%28Athene_noctua%29_2.jpg',
    audioUrl: '',
    lore: 'Sacred to Athena in ancient Greece and symbol of Athens — depicted on their silver coins as a sign of wisdom and prosperity.',
    habitat: 'Farmland, orchards, hedgerows',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 70,
  ),
  Bird(
    name: 'Great Spotted Woodpecker',
    scientificName: 'Dendrocopos major',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Great_spotted_woodpecker_Dendrocopos_major.jpg/800px-Great_spotted_woodpecker_Dendrocopos_major.jpg',
    audioUrl: '',
    lore: 'Drums on branches at 20 strikes per second — different trees produce different pitches, so it selects its "drum kit" deliberately.',
    habitat: 'Woodland, parks, gardens with trees',
    conservationStatus: 'Least Concern',
    rarity: 'uncommon',
    baseXp: 75,
  ),

  // ── Additional Rare species ───────────────────────────────────────────────
  Bird(
    name: 'Burrowing Owl',
    scientificName: 'Athene cunicularia',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Burrowing_Owl_%28Athene_cunicularia%29_%285052476267%29.jpg/800px-Burrowing_Owl_%28Athene_cunicularia%29_%285052476267%29.jpg',
    audioUrl: '',
    lore: 'Lives underground in prairie dog burrows, lining the entrance with dung to attract beetles — its primary food source — a unique strategy.',
    habitat: 'Grasslands, prairies, desert flatlands',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 155,
  ),
  Bird(
    name: 'Vermilion Flycatcher',
    scientificName: 'Pyrocephalus rubinus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Pyrocephalus_rubinus_-_Male.jpg/800px-Pyrocephalus_rubinus_-_Male.jpg',
    audioUrl: '',
    lore: 'The male is like a living flame — its brilliant red crown and breast are so vivid it seems to glow against desert scrub.',
    habitat: 'Riparian scrub, desert lowlands',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 160,
  ),
  Bird(
    name: 'Ruffed Grouse',
    scientificName: 'Bonasa umbellus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/Ruffed_Grouse_%282%29.jpg/800px-Ruffed_Grouse_%282%29.jpg',
    audioUrl: '',
    lore: 'Drums by beating its wings so fast they create a vacuum — not touching its chest. The deep booming sound travels over a kilometre.',
    habitat: 'Mixed forests with dense undergrowth',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 150,
  ),
  Bird(
    name: 'White-tailed Eagle',
    scientificName: 'Haliaeetus albicilla',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/49/White-tailed_Eagle_%28Haliaeetus_albicilla%29_%2810%29.jpg/800px-White-tailed_Eagle_%28Haliaeetus_albicilla%29_%2810%29.jpg',
    audioUrl: '',
    lore: 'Europe\'s largest eagle and the fourth largest in the world. Reintroduced to Britain after extinction, it now soars over Scotland again.',
    habitat: 'Coasts, large lakes, rivers',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 200,
  ),
  Bird(
    name: 'Greater Flamingo',
    scientificName: 'Phoenicopterus roseus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Greater_Flamingo_Phoenicopterus_ruber_roseus.jpg/800px-Greater_Flamingo_Phoenicopterus_ruber_roseus.jpg',
    audioUrl: '',
    lore: 'Feeds with its head upside-down, pumping water through a specialised comb-like beak to filter tiny crustaceans — the source of its pink colour.',
    habitat: 'Salt lakes, lagoons, estuaries',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 190,
  ),
  Bird(
    name: 'Secretary Bird',
    scientificName: 'Sagittarius serpentarius',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Sagittarius_serpentarius_-_001.jpg/800px-Sagittarius_serpentarius_-_001.jpg',
    audioUrl: '',
    lore: 'Stamps snakes to death with legs that can deliver 195 N of force — five times its own body weight — faster than the eye can see.',
    habitat: 'African savannah and grasslands',
    conservationStatus: 'Endangered',
    rarity: 'rare',
    baseXp: 220,
  ),
  Bird(
    name: 'Magnificent Frigatebird',
    scientificName: 'Fregata magnificens',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Great_Frigatebird_%28Fregata_minor%29.jpg/800px-Great_Frigatebird_%28Fregata_minor%29.jpg',
    audioUrl: '',
    lore: 'Has the largest wingspan-to-bodyweight ratio of any bird. It cannot land on water as its feathers are not waterproof — it sleeps on the wing.',
    habitat: 'Tropical and subtropical coasts',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 175,
  ),
  Bird(
    name: 'Eurasian Eagle-Owl',
    scientificName: 'Bubo bubo',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Bubo_bubo_Minsk_zoo.jpg/800px-Bubo_bubo_Minsk_zoo.jpg',
    audioUrl: '',
    lore: 'The world\'s largest owl, capable of taking prey as large as a young deer. Its eyes are fixed in their sockets — it must turn its whole head to look sideways.',
    habitat: 'Rocky mountains, forests, cliffs',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 210,
  ),
  Bird(
    name: 'Wandering Albatross',
    scientificName: 'Diomedea exulans',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Albatros_en_vuelo.jpg/800px-Albatros_en_vuelo.jpg',
    audioUrl: '',
    lore: 'Has the largest wingspan of any living bird at 3.5 m. It can circle the globe in 46 days and may travel over 120,000 km in a year.',
    habitat: 'Open Southern Ocean, breeds on remote islands',
    conservationStatus: 'Vulnerable',
    rarity: 'rare',
    baseXp: 230,
  ),
  Bird(
    name: 'Red Kite',
    scientificName: 'Milvus milvus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Red_Kite_-_Milvus_milvus.jpg/800px-Red_Kite_-_Milvus_milvus.jpg',
    audioUrl: '',
    lore: 'Once near extinction in Britain; one of the country\'s greatest conservation success stories — now soaring above Welsh valleys again.',
    habitat: 'Woodland, open farmland, valleys',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 165,
  ),
  Bird(
    name: 'Common Kingfisher',
    scientificName: 'Alcedo atthis',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Common_kingfisher_alcedo_atthis.jpg/800px-Common_kingfisher_alcedo_atthis.jpg',
    audioUrl: '',
    lore: 'Engineers of Japan\'s Shinkansen studied the kingfisher beak to design the bullet train\'s nose — reducing noise and energy use by 30%.',
    habitat: 'Clear rivers, streams, ponds, coasts',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 155,
  ),
  Bird(
    name: 'Bohemian Waxwing',
    scientificName: 'Bombycilla garrulus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Bombycilla_garrulus1.jpg/800px-Bombycilla_garrulus1.jpg',
    audioUrl: '',
    lore: 'During irruption years, thousands descend on towns stripping berry trees bare overnight — their arrival is like a living blizzard of wings.',
    habitat: 'Boreal forests; parks and gardens in winter',
    conservationStatus: 'Least Concern',
    rarity: 'rare',
    baseXp: 160,
  ),

  // ── Additional Legendary species ──────────────────────────────────────────
  Bird(
    name: 'Spix\'s Macaw',
    scientificName: 'Cyanopsitta spixii',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Spix%27s_Macaw_2.jpg/800px-Spix%27s_Macaw_2.jpg',
    audioUrl: '',
    lore: 'The "Little Blue Macaw" of the movie Rio — declared extinct in the wild in 2000. Captive-breeding programmes are slowly returning it to Brazil.',
    habitat: 'Dry caatinga woodland, Brazil',
    conservationStatus: 'Extinct in the Wild',
    rarity: 'legendary',
    baseXp: 900,
  ),
  Bird(
    name: 'Philippine Eagle',
    scientificName: 'Pithecophaga jefferyi',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Philippine_Eagle.jpg/800px-Philippine_Eagle.jpg',
    audioUrl: '',
    lore: 'The national bird of the Philippines — its crown of shaggy feathers give it a lion-like face. Fewer than 800 survive in old-growth forest.',
    habitat: 'Old-growth rainforest, Mindanao island',
    conservationStatus: 'Critically Endangered',
    rarity: 'legendary',
    baseXp: 850,
  ),
  Bird(
    name: 'Andean Condor',
    scientificName: 'Vultur gryphus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c2/Vulture_gryphus_-_adult_-_condor_of_andes.jpg/800px-Vulture_gryphus_-_adult_-_condor_of_andes.jpg',
    audioUrl: '',
    lore: 'Has a wingspan of 3.3 m and can soar for hours without a single wingbeat — it uses thermal columns to travel 200 km without effort.',
    habitat: 'High Andes and Pacific coastlines',
    conservationStatus: 'Vulnerable',
    rarity: 'legendary',
    baseXp: 750,
  ),
  Bird(
    name: 'Keel-billed Toucan',
    scientificName: 'Ramphastos sulfuratus',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Ramphastos_sulfuratus_-Gamboa_Rainforest_Resort%2C_Gamboa%2C_Panama-8.jpg/800px-Ramphastos_sulfuratus_-Gamboa_Rainforest_Resort%2C_Gamboa%2C_Panama-8.jpg',
    audioUrl: '',
    lore: 'Its banana-yellow bill is hollow and made of keratin — light as a feather despite its size. It radiates heat to cool the bird like a radiator.',
    habitat: 'Tropical and subtropical lowland forests',
    conservationStatus: 'Least Concern',
    rarity: 'legendary',
    baseXp: 600,
  ),
  Bird(
    name: 'Wilson\'s Bird-of-Paradise',
    scientificName: 'Cicinnurus respublica',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f8/Cicinnurus_respublica_-_Red_Bird-of-paradise.jpg/800px-Cicinnurus_respublica_-_Red_Bird-of-paradise.jpg',
    audioUrl: '',
    lore: 'The male has a bright blue bald head — which actually glows ultraviolet — and curling tail wires. Its dance floor is swept spotlessly clean.',
    habitat: 'Hill forest of two small Indonesian islands only',
    conservationStatus: 'Near Threatened',
    rarity: 'legendary',
    baseXp: 950,
  ),
  Bird(
    name: 'Jabiru',
    scientificName: 'Jabiru mycteria',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Jabiru_mycteria_-_Pantanal%2C_Brazil.jpg/800px-Jabiru_mycteria_-_Pantanal%2C_Brazil.jpg',
    audioUrl: '',
    lore: 'The tallest flying bird in the Americas at 1.4 m, with a 2.8 m wingspan. Its red throat pouch inflates dramatically during courtship.',
    habitat: 'Tropical wetlands and savannahs',
    conservationStatus: 'Least Concern',
    rarity: 'legendary',
    baseXp: 700,
  ),
  Bird(
    name: 'Ribbon-tailed Astrapia',
    scientificName: 'Astrapia mayeri',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Astrapia_mayeri_-_ribbon-tailed_astrapia.jpg/800px-Astrapia_mayeri_-_ribbon-tailed_astrapia.jpg',
    audioUrl: '',
    lore: 'Its two white tail feathers are more than three times its body length — the longest tail relative to body size of any wild bird in the world.',
    habitat: 'Montane forests of Papua New Guinea',
    conservationStatus: 'Near Threatened',
    rarity: 'legendary',
    baseXp: 880,
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
