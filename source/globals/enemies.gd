@tool
class_name Enemies extends RefCounted




const CAT = "cat"
const DECLAWED = "declawed"
const NPCS = "npcs"
const TRAFFIC = "traffic"
const BOTTOM_FEEDER = "bottom_feeder"
const FILTER_FEEDER = "filter_feeder"


const NOPPY = "noppy"
const SOPPY = "soppy"
const PEOPLE = "people"
const DECEDENT = "decedent"
const STOKER = "stoker"
const BROKER = "broker"


const BOOKWORM = "bookworm"
const MILKWORM = "milkworm"
const FAT_CAT = "fat_cat"
const PURRGEOISIE = "purrgeoisie"
const URCHIN = "urchin"
const LUMP = "lump"


const ELMER = "elmer"



const ANTI_SEX_WORKER = "anti_sex_worker"
const SEX_TRAITOR = "sex_traitor"
const SNOWBALL = "snowball"
const EIGHTBALL = "eightball"
const PADDLERS = "paddlers"
const SOCIAL_CLIMBERS = "social_climbers"


const FREEZER = "freezer"
const FOREIGN_BODY = "foreign_body"
const LIQUID_HUMAN = "liquid_human"
const PROTO_COP = "proto_cop"
const STRAWMAN = "strawman"
const HOUSEBROKEN = "housebroken"


const GREEB = "greeb"
const UFO = "ufo"
const DEW_JUBILIST = "dew_jubilist"
const DEW_JUBAJALIST = "dew_jubajalist"
const XRAFSTAR = "xrafstar"
const PSEUD = "pseud"


const BRUTALIST = "brutalist"



const HERARRA = "herarra"
const JUVENILE = "juvenile"
const PROLE_SERVICE = "prole_service"
const RECEIVER = "receiver"
const PRODIGY = "prodigy"
const INVALID = "invalid"


const UMAMI = "umami"
const SALT = "salt"
const RUBBER_ANIMAL = "rubber_animal"
const PINK_RUBBER_ANIMAL = "pink_rubber_animal"
const PARADIGM = "paradigm"
const COPYCAT = "copycat"


const NEW_COP = "new_cop"
const SHERIFF = "sheriff"
const VAMPIRE = "vampire"
const PARASITE = "parasite"
const AGE_REGRESSOR = "age_regressor"
const TRAUMA_CORE = "trauma_core"


const BAMMON = "bammon"


const NOBODY = "nobody"


const SHADOWS = {

 CAT: DECLAWED, 
 NPCS: TRAFFIC, 
 BOTTOM_FEEDER: FILTER_FEEDER, 


 NOPPY: SOPPY, 
 PEOPLE: DECEDENT, 
 STOKER: BROKER, 


 BOOKWORM: MILKWORM, 
 FAT_CAT: PURRGEOISIE, 
 URCHIN: LUMP, 


 ANTI_SEX_WORKER: SEX_TRAITOR, 
 SNOWBALL: EIGHTBALL, 
 PADDLERS: SOCIAL_CLIMBERS, 


 LIQUID_HUMAN: PROTO_COP, 
 FREEZER: FOREIGN_BODY, 
 STRAWMAN: HOUSEBROKEN, 


 GREEB: UFO, 
 DEW_JUBILIST: DEW_JUBAJALIST, 
 XRAFSTAR: PSEUD, 


 HERARRA: JUVENILE, 
 PRODIGY: INVALID, 
 PROLE_SERVICE: RECEIVER, 


 UMAMI: SALT, 
 RUBBER_ANIMAL: PINK_RUBBER_ANIMAL, 
 PARADIGM: COPYCAT, 


 NEW_COP: SHERIFF, 
 VAMPIRE: PARASITE, 
 AGE_REGRESSOR: TRAUMA_CORE, 
}

const HEALTH_SCALING = {

 CAT: [16, 20, 24, 28], 
 DECLAWED: [20, 24, 28, 32], 
 NPCS: [16, 20, 24, 28], 
 TRAFFIC: [18, 22, 26, 30], 
 BOTTOM_FEEDER: [16, 20, 24, 28], 

 NOPPY: [18, 22, 26, 30], 
 PEOPLE: [24, 26, 30, 34], 
 STOKER: [18, 22, 26, 30], 
 BROKER: [24, 26, 30, 34], 

 URCHIN: [16, 20, 24, 28], 
 LUMP: [24, 28, 32, 36], 
 BOOKWORM: [20, 24, 28, 32], 
 FAT_CAT: [24, 26, 30, 34], 

 ELMER: [42, 48, 54, 64], 


 ANTI_SEX_WORKER: [24, 26, 30, 34], 
 PADDLERS: [20, 24, 28, 32], 
 SOCIAL_CLIMBERS: [24, 26, 30, 34], 
 SNOWBALL: [24, 26, 30, 34], 

 FREEZER: [32, 36, 40, 44], 
 FOREIGN_BODY: [28, 32, 36, 40], 
 LIQUID_HUMAN: [24, 26, 30, 34], 
 STRAWMAN: [36, 42, 48, 52], 
 HOUSEBROKEN: [42, 48, 54, 58], 

 XRAFSTAR: [24, 26, 30, 34], 
 GREEB: [28, 32, 36, 40], 
 DEW_JUBILIST: [28, 32, 36, 40], 

 BRUTALIST: [48, 52, 56, 66], 


 PRODIGY: [26, 30, 34, 38], 
 HERARRA: [26, 28, 30, 34], 
 PROLE_SERVICE: [30, 32, 36, 40], 

 UMAMI: [26, 30, 34, 38], 
 RUBBER_ANIMAL: [32, 36, 40, 44], 
 PARADIGM: [42, 46, 50, 54], 

 VAMPIRE: [30, 36, 42, 46], 
 NEW_COP: [42, 50, 56, 60], 
 AGE_REGRESSOR: [26, 28, 30, 34], 
 TRAUMA_CORE: [28, 32, 36, 40], 

 BAMMON: [60, 70, 80, 90], 
}

const CHARACTERS = Globals.CHARACTERS
const NOBODY_HEALTH_SCALING = {
 CHARACTERS.LEXICOGRAPHER: [50, 55, 65, 75], 
 CHARACTERS.JUBILIST: [
  [26, 30, 34, 42], 
  [32, 36, 40, 48], 
  [18, 22, 26, 34], 
 ], 
 CHARACTERS.CHILD: [60, 70, 80, 90], 
 CHARACTERS.FISHER: [60, 70, 80, 90], 
 CHARACTERS.ADDICT: [60, 70, 80, 90], 
}

const G_MUSIC = Globals.MUSIC
const MUSIC = {
 CAT: G_MUSIC.PREFACE, DECLAWED: G_MUSIC.I_WONDER_IF, 
 NPCS: G_MUSIC.PREFACE, TRAFFIC: G_MUSIC.I_WONDER_IF, 
 BOTTOM_FEEDER: G_MUSIC.PREFACE, FILTER_FEEDER: G_MUSIC.I_WONDER_IF, 
 NOPPY: G_MUSIC.DROPCAP, SOPPY: G_MUSIC.IF_YOU_WANT, 
 PEOPLE: G_MUSIC.RETCON, DECEDENT: G_MUSIC.FAILURE_TO_THRIVE, 
 STOKER: G_MUSIC.HEADLINE, BROKER: G_MUSIC.WE_WERE_THERE, 
 URCHIN: G_MUSIC.HEADLINE, LUMP: G_MUSIC.IT_DID_IT, 
 BOOKWORM: G_MUSIC.HEADLINE, MILKWORM: G_MUSIC.TO_STAY_DEAD, 
 FAT_CAT: G_MUSIC.RETCON, PURRGEOISIE: G_MUSIC.IF_YOU_WANT, 
 ELMER: G_MUSIC.TYPEFACE, 

 PADDLERS: G_MUSIC.PATHOS, SOCIAL_CLIMBERS: G_MUSIC.THEY_FOUND_TOMORROW, 
 FREEZER: G_MUSIC.DROPCAP, FOREIGN_BODY: G_MUSIC.WHAT_WAS_SHE, 
 SNOWBALL: G_MUSIC.DROPCAP, EIGHTBALL: G_MUSIC.THEY_FOUND_TOMORROW, 
 ANTI_SEX_WORKER: G_MUSIC.WAXSTAMP, SEX_TRAITOR: G_MUSIC.IT_DID_IT, 
 LIQUID_HUMAN: G_MUSIC.ASTERISK, PROTO_COP: G_MUSIC.TO_STAY_DEAD, 
 STRAWMAN: G_MUSIC.LOGOS_LOOP, HOUSEBROKEN: G_MUSIC.IF_YOU_WANT_LOOP, 
 XRAFSTAR: G_MUSIC.ASTERISK, PSEUD: G_MUSIC.FAILURE_TO_THRIVE, 
 GREEB: G_MUSIC.ASTERISK, UFO: G_MUSIC.THERE_HE_GOES, 
 DEW_JUBILIST: G_MUSIC.PATHOS, DEW_JUBAJALIST: G_MUSIC.IT_DID_IT, 
 BRUTALIST: G_MUSIC.BODY_PARAGRAPH, 

 HERARRA: G_MUSIC.LOGOS, JUVENILE: G_MUSIC.FAILURE_TO_THRIVE, 
 PROLE_SERVICE: G_MUSIC.LOGOS, RECEIVER: G_MUSIC.THERE_HE_GOES, 
 PRODIGY: G_MUSIC.ETHOS, INVALID: G_MUSIC.THERE_HE_GOES, 
 UMAMI: G_MUSIC.WAXSTAMP, SALT: G_MUSIC.WHAT_WAS_SHE, 
 RUBBER_ANIMAL: G_MUSIC.RETCON, PINK_RUBBER_ANIMAL: G_MUSIC.WHAT_WAS_SHE, 
 PARADIGM: G_MUSIC.PATHOS, COPYCAT: G_MUSIC.WE_WERE_THERE, 
 VAMPIRE: G_MUSIC.WAXSTAMP, PARASITE: G_MUSIC.WE_WERE_THERE, 
 NEW_COP: G_MUSIC.ETHOS, SHERIFF: G_MUSIC.TO_STAY_DEAD, 
 AGE_REGRESSOR: G_MUSIC.ETHOS, TRAUMA_CORE: G_MUSIC.THEY_FOUND_TOMORROW, 
 BAMMON: G_MUSIC.INTERROBANG, 

 NOBODY: G_MUSIC.MX, 
}

const GLOBAL_HEARTS = Globals.HEARTS
const HEARTS = {
 PEOPLE: GLOBAL_HEARTS.PEOPLE, 
 BOOKWORM: GLOBAL_HEARTS.FIREBUG, 
 ELMER: GLOBAL_HEARTS.PLANT, 
 XRAFSTAR: GLOBAL_HEARTS.BUG, 
 SNOWBALL: GLOBAL_HEARTS.ASH, 
 FREEZER: GLOBAL_HEARTS.ICE, 
 FOREIGN_BODY: GLOBAL_HEARTS.ICE, 
 GREEB: GLOBAL_HEARTS.ALIUM, 
 PROTO_COP: GLOBAL_HEARTS.COP, 
 NEW_COP: GLOBAL_HEARTS.COP, 
 HERARRA: GLOBAL_HEARTS.PLANT, 
 STRAWMAN: GLOBAL_HEARTS.PHONE, 
 HOUSEBROKEN: GLOBAL_HEARTS.PHONE, 
 EIGHTBALL: GLOBAL_HEARTS.CHASER
}

const BOSSES = [
 ELMER, 
 BRUTALIST, 
 BAMMON, 
 NOBODY, 
]

const AMBUSH = [
 NPCS, 
 TRAFFIC, 
 ELMER, 
 GREEB, 
 UFO, 
 LIQUID_HUMAN, 
 PROTO_COP, 
 FREEZER, 
 FOREIGN_BODY, 
]

const PRIORITY_ENCOUNTERS = [
 CAT, 
 FREEZER, 
 NEW_COP, 
]

const DEPRIORITY_ENCOUNTERS = [
 STOKER, 
 PRODIGY
]

const POOLS = [
 [
  [CAT, NPCS, BOTTOM_FEEDER], 
  [NOPPY, PEOPLE, STOKER], 
  [BOOKWORM, FAT_CAT, URCHIN], 
  [ELMER], 
 ], 
 [
  [ANTI_SEX_WORKER, SNOWBALL, PADDLERS], 
  [FREEZER, LIQUID_HUMAN, STRAWMAN], 
  [GREEB, DEW_JUBILIST, XRAFSTAR], 
  [BRUTALIST], 
 ], 
 [
  [HERARRA, PROLE_SERVICE, PRODIGY], 
  [UMAMI, RUBBER_ANIMAL, PARADIGM], 
  [NEW_COP, VAMPIRE, AGE_REGRESSOR], 
  [BAMMON], 
  [NOBODY], 
 ], 
]

const PHONEBOOK_IDLE_OVERRIDE = {
 PADDLERS: "yaoi_idle", 
 SOCIAL_CLIMBERS: "yaoi_idle", 
 NOBODY: "phonebook", 
}

const PHONEBOOK_ANIMS = {
 CAT: [["swipe_start", "swipe_a", "swipe_b", "swipe_a", "swipe_end_phonebook"], "bite", "flinch"], 
 BOTTOM_FEEDER: ["bash", "sneeze", "flinch"], 

 NOPPY: ["blow_bubble", "bubble_balloon", "flinch"], 
 PEOPLE: ["attack", "flinch"], 
 STOKER: ["shovel", "bash"], 

 BOOKWORM: ["spit_phonebook", "lunge"], 
 FAT_CAT: [["knead_start", "knead_a", "knead_b", "knead_a", "knead_b", "knead_end_phonebook"], "lick"], 
 URCHIN: ["psych_up", "bat"], 
 LUMP: ["bat_alt"], 

 ELMER: ["ask_deborah", "announce", "flinch"], 

 ANTI_SEX_WORKER: ["period_cramp", "picket"], 
 SEX_TRAITOR: ["traitor_cramp", "picket"], 
 SNOWBALL: [["drag", "appear"], "flinch"], 
 PADDLERS: [
  {animations = ["yuri_start", "yaoi_cycle", "yuri_stop", "yuri_idle"], no_idle = true}, 
  {animations = ["yaoi_start", "yuri_cycle", "yaoi_stop", "yaoi_idle"], no_idle = true}, 
 ], 
 SOCIAL_CLIMBERS: [
  {animations = ["yaoi_yuri", "yuri_idle"], no_idle = true}, 
  {animations = ["yuri_yaoi", "yaoi_idle"], no_idle = true}, 
 ], 

 FREEZER: ["explode"], 
 FOREIGN_BODY: ["explode_foreign"], 
 LIQUID_HUMAN: ["attack", "flinch"], 

 GREEB: ["bong_rip", "flinch"], 
 UFO: [["swoop", "appear"], ["die_foucault", "RESET"]], 
 DEW_JUBILIST: ["wicked_elixir", "pranxis"], 
 XRAFSTAR: ["extrude", "pollute"], 

 BRUTALIST: ["sprawl", "flinch"], 

 HERARRA: [["slam_start", "slam", "slam_end"], "shredder"], 
 PROLE_SERVICE: [["raise_phone", "smash_phone", "phone_ring", "answer_phone"], ["raise_phone", "bash"]], 
 PRODIGY: ["wail", "shriek"], 

 UMAMI: [{animation = "kneel", no_idle = true}, "lash"], 
 RUBBER_ANIMAL: ["spit", "lunge"], 
 PARADIGM: ["toss", "flinch"], 

 NEW_COP: ["shoot", "flinch"], 
 SHERIFF: ["pop_pop", "flinch"], 
 VAMPIRE: ["spill", ["bite_start", "bite_end"], "drank"], 
 AGE_REGRESSOR: ["attack", "flinch"], 

 BAMMON: [["uncork", "uncork_end"], ["pull", "pull_end"], "flinch"], 
 NOBODY: ["phonebook_flinch"], 
}

const PHONEBOOK_UNCLIPPED = {
 PEOPLE: true, 
 FAT_CAT: true, 
 URCHIN: true, 
 ELMER: true, 
 XRAFSTAR: true, 
 HERARRA: true, 
 PROLE_SERVICE: true, 
 BAMMON: true, 
}

static func list(include_shadows: = true) -> PackedStringArray:
 var enemies: = PackedStringArray()
 for act_pool in POOLS:
  for floor_pool in act_pool:
   for id in floor_pool:
    enemies.append(id)
    if include_shadows and id in SHADOWS:
     enemies.append(SHADOWS[id])

 return enemies


static func get_act_and_floor(enemy_id) -> Variant:
 var base_enemy = SHADOWS.find_key(enemy_id)
 if base_enemy != null:
  enemy_id = base_enemy

 for act_index in POOLS.size():
  var act_pool = POOLS[act_index]
  for floor_index in act_pool.size():
   var floor_pool = act_pool[floor_index]
   if enemy_id in floor_pool:
    return {
     act = act_index, 
     floor = floor_index
    }

 return null


static func get_icon_frame_coord(enemy_id: String) -> Vector2i:
 if is_shadow(enemy_id):
  enemy_id = SHADOWS.find_key(enemy_id)

 for act_index in POOLS.size():
  var floor_act_index: int = 0
  var act_pool = POOLS[act_index]
  for floor_index in act_pool.size():
   var floor_pool = act_pool[floor_index]
   if enemy_id in floor_pool:
    return Vector2i(floor_act_index + floor_pool.find(enemy_id), act_index)

   floor_act_index += floor_pool.size()

 return Vector2i(0, 0)


static func is_shadow(enemy_id: String) -> bool:
 return SHADOWS.find_key(enemy_id) != null


static func is_enemy_or_shadow(enemy_id: String, match_id: String) -> bool:
 if enemy_id == match_id:
  return true
 elif is_shadow(match_id) and enemy_id == get_base_enemy(match_id):
  return true
 elif is_shadow(enemy_id) and match_id == get_base_enemy(enemy_id):
  return true

 return false


static func get_base_enemy(shadow_id: String) -> String:
 return SHADOWS.find_key(shadow_id)


static func get_phonebook_animations(enemy_id: String) -> Array:
 if enemy_id in PHONEBOOK_ANIMS:
  return PHONEBOOK_ANIMS[enemy_id]

 if is_shadow(enemy_id):
  return get_phonebook_animations(get_base_enemy(enemy_id))

 return []


static func enemy_in_pool(enemy_id: String, pool: Array) -> bool:
 if enemy_id in pool:
  return true
 elif is_shadow(enemy_id) and get_base_enemy(enemy_id) in pool:
  return true

 return false
