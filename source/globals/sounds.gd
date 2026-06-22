@tool
class_name Sounds extends RefCounted

const UI: Dictionary[String, Dictionary] = {
 TILE_CLICK = {
  SOUNDS = [
   preload("res://sounds/typewriter1.wav"), 
   preload("res://sounds/typewriter2.wav"), 
   preload("res://sounds/typewriter3.wav")
  ], 
 }, 
 TEXT_TYPING = {
  SOUNDS = [
   preload("res://sounds/ui/text_typing.wav"), 
   preload("res://sounds/ui/text_typing2.wav"), 
   preload("res://sounds/ui/text_typing3.wav"), 
  ], 
  PITCH_VARIANCE = 0.01, 
  STOP_ON_PLAY = true, 
 }, 
 WORD_SUBMIT = {
  SOUND = preload("res://sounds/wordsubmit.wav")
 }, 
 MENU_BUTTON = {
  SOUND = preload("res://sounds/woodplace.wav"), 
  PITCH_VARIANCE = 0.025, 
  STOP_ON_PLAY = true, 
 }, 
 SLIDER = {
  SOUND = preload("res://sounds/ui/slider.wav"), 
  PITCH_VARIANCE = 0.01, 
  VOLUME = 0.3, 
  STOP_ON_PLAY = true, 
 }, 
 BACK = {
  SOUND = preload("res://sounds/ui/back.wav"), 
 }, 
 BACK_PAPER = {
  SOUNDS = [
   preload("res://sounds/ui/paper2.wav"), 
   preload("res://sounds/ui/paper4.wav"), 
  ], 
 }, 
 FORWARD_PAPER = {
  SOUNDS = [
   preload("res://sounds/ui/paper1.wav"), 
   preload("res://sounds/ui/paper3.wav"), 
  ]
 }, 
 CHAR_SELECT = {
  SOUND = preload("res://sounds/ui/charselect.wav"), 
 }, 
 DIFFICULTY = {
  SOUND = preload("res://sounds/ui/difficulty.wav"), 
 }, 
 DIFFICULTY_HARDEST = {
  SOUND = preload("res://sounds/ui/difficultyhardest.wav"), 
 }, 
 SHADOW_OFF = {
  SOUND = preload("res://sounds/ui/shadowoff.wav"), 
 }, 
 SHADOW_ON = {
  SOUND = preload("res://sounds/ui/shadowon.wav"), 
 }, 
 ACHIEVEMENT_RIP = {
  SOUND = preload("res://sounds/ui/achievementrip.wav"), 
 }, 
 ACHIEVEMENT_POPUP = {
  SOUND = preload("res://sounds/ui/achievementpopup.wav"), 
 }, 
 EVIL_DEVELOPER_LAUGHTER = {
  SOUND = preload("res://sounds/hazel.wav"), 
  VOLUME = 0.3, 
 }, 
}

const GENERIC: Dictionary[String, Dictionary] = {
 APPLY_STATUS = {
  SOUND = preload("res://sounds/statuses/statusinflict.wav"), 
 }, 
 HEAL = {
  SOUND = preload("res://sounds/heal.wav"), 
 }, 
 BLOOD_EXPLODE = {
  SOUND = preload("res://sounds/explode.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 HIT = {
  SOUND = preload("res://sounds/characters/generic/player_hit.wav"), 
 }, 
 BOARD_OUT = {
  SOUND = preload("res://sounds/ui/boardslidedown.wav"), 
 }, 
 BOARD_IN = {
  SOUND = preload("res://sounds/ui/boardslideup.wav"), 
 }, 
}

const TILE: Dictionary[String, Dictionary] = {
 WOOD = {
  SOUND = preload("res://sounds/woodplace.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 PLASTIC = {
  SOUND = preload("res://sounds/plasticplace.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 POISON = {
  SOUND = preload("res://sounds/statuses/poisontile1.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 COAL = {
  SOUND = preload("res://sounds/statuses/coaltile.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 COAL_CRUMBLE = {
  SOUND = preload("res://sounds/statuses/coalcrumble.wav")
 }, 
 BURNING = {
  SOUND = preload("res://sounds/statuses/firetile.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 BURNING_BURN_OUT = {
  SOUND = preload("res://sounds/statuses/firetileburn.wav")
 }, 
 BLEED = {
  SOUND = preload("res://sounds/statuses/bleed.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 CRIT = {
  SOUND = preload("res://sounds/statuses/crittile.wav"), 
  PITCH_VARIANCE = 0.25, 
  VOLUME = 0.4, 
 }, 
 CURSED = {
  SOUND = preload("res://sounds/statuses/cursedtile.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 MONEY = {
  SOUND = preload("res://sounds/statuses/moneytile.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 BRUISE = {
  SOUND = preload("res://sounds/statuses/bruise.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 FROZEN = {
  SOUNDS = [
   preload("res://sounds/statuses/frozen1.wav"), 
   preload("res://sounds/statuses/frozen2.wav"), 
  ], 
  PITCH_VARIANCE = 0.025, 
 }, 
 LINKED = {
  SOUND = preload("res://sounds/statuses/chain.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 TARNISHED = {
  SOUND = preload("res://sounds/statuses/tarnished.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 CANDY = {
  SOUND = preload("res://sounds/statuses/candy.wav"), 
  PITCH_VARIANCE = 0.025, 
  VOLUME = 0.3, 
 }, 
 ASH = {
  SOUND = preload("res://sounds/statuses/ash.wav"), 
  PITCH_VARIANCE = 0.025, 
  VOLUME = 0.4, 
 }, 
 ETERNAL = {
  SOUND = preload("res://sounds/statuses/eternal.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 BOMB_WARNING = {
  SOUND = preload("res://sounds/statuses/bombwarning.wav"), 
 }, 
 BOMB_UHOH = {
  SOUND = preload("res://sounds/statuses/bombuhoh.wav"), 
 }, 
 BOMB_DETONATE = {
  SOUND = preload("res://sounds/statuses/bombdetonate.wav"), 
 }, 
 BOMB_CRIT = {
  SOUND = preload("res://sounds/statuses/bombcrit.wav"), 
  VOLUME = 0.5, 
  PITCH_VARIANCE = 0.025, 
 }, 
 ACID = {
  SOUND = preload("res://sounds/statuses/acid.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 ACID_MELT = {
  SOUND = preload("res://sounds/statuses/acidmelt.wav"), 
 }, 
 GUNK = {
  SOUND = preload("res://sounds/statuses/gunk.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
}


const CHARACTER: Dictionary[String, Dictionary] = {
 ATTACK = {
  SOUND = preload("res://sounds/characters/generic/player_hit.wav"), 
  PITCH_VARIANCE = 0.05, 
 }, 
 HURT = {
  SOUND = preload("res://sounds/characters/generic/player_hurt.wav"), 
 }, 
 BLOCK = {
  SOUND = preload("res://sounds/characters/generic/player_block.wav"), 
 }, 
 STEP = {
  SOUNDS = [
   preload("res://sounds/characters/generic/footstep1.wav"), 
   preload("res://sounds/characters/generic/footstep2.wav"), 
   preload("res://sounds/characters/generic/footstep3.wav"), 
  ], 
  PITCH_VARIANCE = 0.05, 
 }, 
}

const LEXICOGRAPHER: Dictionary[String, Dictionary] = {
 DIE = {
  SOUND = preload("res://sounds/characters/lexicographer/lexicographerdeath.wav"), 
 }, 
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/characters/lexicographer/lexicographerhurt1.wav"), 
   preload("res://sounds/characters/lexicographer/lexicographerhurt2.wav"), 
   preload("res://sounds/characters/lexicographer/lexicographerhurt3.wav"), 
  ], 
 }, 
 BOOK_FUMBLE = {
  SOUNDS = [
   preload("res://sounds/characters/lexicographer/bookfumble1.wav"), 
   preload("res://sounds/characters/lexicographer/bookfumble2.wav"), 
   preload("res://sounds/characters/lexicographer/bookfumble3.wav"), 
  ], 
  IGNORE_SPRITE_PITCH = true, 
 }, 
}

const JUBILIST: Dictionary[String, Dictionary] = {
 DIE = {
  SOUND = preload("res://sounds/characters/jubilist/jubilistdeath.wav")
 }, 
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/characters/jubilist/jubilisthurt1.wav"), 
   preload("res://sounds/characters/jubilist/jubilisthurt2.wav"), 
   preload("res://sounds/characters/jubilist/jubilisthurt3.wav"), 
  ]
 }, 
}

const CHILD: Dictionary[String, Dictionary] = {
 DIE = {
  SOUND = preload("res://sounds/characters/child/childhurt3.wav"), 
 }, 
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/characters/child/childhurt1.wav"), 
   preload("res://sounds/characters/child/childhurt2.wav"), 
   preload("res://sounds/characters/child/childhurt3.wav"), 
  ], 
 }, 
 DODGE = {
  SOUND = preload("res://sounds/characters/child/childdodge.wav"), 
  IGNORE_SPRITE_PITCH = true, 
 }, 
 DODGE_VOX = {
  SOUNDS = [
   preload("res://sounds/characters/child/childdodgevox1.wav"), 
   preload("res://sounds/characters/child/childdodgevox2.wav"), 
  ]
 }, 
}

const FISHER: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/characters/fisher/fisherhurt1.wav"), 
   preload("res://sounds/characters/fisher/fisherhurt2.wav"), 
   preload("res://sounds/characters/fisher/fisherhurt3.wav"), 
  ], 
 }, 
 DIE = {
  SOUND = preload("res://sounds/characters/fisher/fisherdeath.wav"), 
 }, 
 HUM = {
  SOUNDS = [
   preload("res://sounds/characters/fisher/fisherhum1.wav"), 
   preload("res://sounds/characters/fisher/fisherhum2.wav"), 
   preload("res://sounds/characters/fisher/fisherhum3.wav"), 
   preload("res://sounds/characters/fisher/fisherhum4.wav"), 
   preload("res://sounds/characters/fisher/fisherhum5.wav"), 
   preload("res://sounds/characters/fisher/fisherhum6.wav"), 
   preload("res://sounds/characters/fisher/fisherhum7.wav"), 
   preload("res://sounds/characters/fisher/fisherhum8.wav"), 
   preload("res://sounds/characters/fisher/fisherhum9.wav"), 
   preload("res://sounds/characters/fisher/fisherhum10.wav"), 
  ], 
 }, 
 FISH_DASH = {
  SOUND = preload("res://sounds/characters/fisher/fisherdash.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 FISH_EVIL = {
  SOUND = preload("res://sounds/characters/fisher/fisherevil.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 FISH_LAND = {
  SOUNDS = [
   preload("res://sounds/statuses/fishland1.wav"), 
   preload("res://sounds/statuses/fishland2.wav"), 
  ], 
  PITCH_VARIANCE = 0.025, 
 }, 
 REEL = {
  SOUNDS = [
   preload("res://sounds/characters/fisher/fisherreel1.wav"), 
   preload("res://sounds/characters/fisher/fisherreel2.wav"), 
  ]
 }, 
 REEL_IN = {
  SOUND = preload("res://sounds/characters/fisher/fisherreelin.wav"), 
 }, 
 REEL_OUT = {
  SOUND = preload("res://sounds/characters/fisher/fisherreelout.wav"), 
 }, 
 SPLASH = {
  SOUND = preload("res://sounds/characters/fisher/fishersplash.wav"), 
  PITCH_VARIANCE = 0.025, 
 }
}

const ADDICT: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/characters/addict/addicthurt1.wav"), 
   preload("res://sounds/characters/addict/addicthurt2.wav"), 
   preload("res://sounds/characters/addict/addicthurt3.wav"), 
  ], 
 }, 
 DIE = {
  SOUND = preload("res://sounds/characters/addict/addictdeath.wav"), 
 }, 
 STOP = {
  SOUND = preload("res://sounds/characters/addict/addictstop.wav"), 
 }, 
}


const CAT: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUND = preload("res://sounds/cat/catflinch.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/cat/catdeath.wav"), 
 }, 
 SWIPE = {
  SOUNDS = [
   preload("res://sounds/cat/quick_swish_01.wav"), 
   preload("res://sounds/cat/quick_swish_02.wav"), 
   preload("res://sounds/cat/quick_swish_03.wav"), 
  ]
 }, 
 BITE_WINDUP = {
  SOUND = preload("res://sounds/cat/cat_bites.wav"), 
 }, 
 BITE = {
  SOUND = preload("res://sounds/cat/bear_trap.wav"), 
 }, 
}

const NPC: Dictionary[String, Dictionary] = {
 ATTACK = {
  SOUND = preload("res://sounds/npc/npcattack.wav")
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/npc/npcflinch.wav")
 }, 
 LOOP = {
  SOUND = preload("res://sounds/npc/NPCLoop.ogg"), 
  STOP_ON_TREE_EXIT = true, 
 }, 
 TRAFFIC = {
  SOUND = preload("res://sounds/npc/npctraffic.wav")
 }, 
}

const BOTTOM_FEEDER: Dictionary[String, Dictionary] = {
 ATTACK = {
  SOUND = preload("res://sounds/bottomfeeder/bottomattack.wav"), 
 }, 
 SUCK = {
  SOUND = preload("res://sounds/bottomfeeder/bottomsuck.wav"), 
 }, 
 FILTER_SUCK = {
  SOUND = preload("res://sounds/bottomfeeder/filtersuck.wav"), 
 }, 
 COLLECT = {
  SOUND = preload("res://sounds/bottomfeeder/bottomcollect.wav"), 
 }, 
 FINISH = {
  SOUND = preload("res://sounds/bottomfeeder/bottomfinish.wav"), 
 }, 
 SPIT = {
  SOUND = preload("res://sounds/bottomfeeder/bottomspit.wav"), 
 }, 
 HIT = {
  SOUND = preload("res://sounds/bottomfeeder/bottomhit.wav"), 
 }, 
 SQUEAK = {
  SOUND = preload("res://sounds/bottomfeeder/bottomsqueak.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/bottomfeeder/bottomdeath.wav"), 
 }, 
}

const NOPPY: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUND = preload("res://sounds/noppy/noppyflinch.wav"), 
 }, 
 INFLATE_SMALL = {
  SOUND = preload("res://sounds/noppy/noppyinflate1.wav")
 }, 
 INFLATE_BIG = {
  SOUND = preload("res://sounds/noppy/noppyinflate2.wav")
 }, 
 POP = {
  SOUND = preload("res://sounds/noppy/noppypoppy.wav"), 
 }, 
 FLOAT_AWAY = {
  SOUND = preload("res://sounds/noppy/noppyleave.wav"), 
 }, 
}

const PEOPLE: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUND = preload("res://sounds/people/peopleflinch.wav"), 
 }, 

 DEATH = {
  SOUND = preload("res://sounds/people/peopledeath.wav"), 
 }, 
 GET_UP = {
  SOUND = preload("res://sounds/people/peoplegetup.wav"), 
 }, 
 JUMP = {
  SOUND = preload("res://sounds/people/peoplejump.wav"), 
 }, 
 SLAM = {
  SOUND = preload("res://sounds/people/peopleslam.wav"), 
 }, 
}

const STOKER: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUND = preload("res://sounds/stoker/stokerflinch.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/stoker/stokerdeath.wav"), 
 }, 
 SHOVEL = {
  SOUND = preload("res://sounds/stoker/stokershovel.wav"), 
 }, 
 SWING = {
  SOUND = preload("res://sounds/stoker/stokerswing.wav"), 
 }, 
}

const BOOKWORM: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUND = preload("res://sounds/bookworm/bookwormflinch.wav"), 
 }, 
 ATTACK = {
  SOUND = preload("res://sounds/bookworm/bookwormattack.wav"), 
 }, 
 FIREBALL = {
  SOUNDS = [
   preload("res://sounds/bookworm/bookwormfireball1.wav"), 
   preload("res://sounds/bookworm/bookwormfireball2.wav"), 
  ], 
 }, 
 FIREBALL_FINAL = {
  SOUND = preload("res://sounds/bookworm/bookwormfinalball.wav"), 
 }, 
 MILKWORM_FIREBALL = {
  SOUNDS = [
   preload("res://sounds/bookworm/milkwormfireball1.wav"), 
   preload("res://sounds/bookworm/milkwormfireball2.wav"), 
  ], 
 }, 
 MILKWORM_FIREBALL_FINAL = {
  SOUND = preload("res://sounds/bookworm/milkwormfinalfireball.wav"), 
 }, 
}

const FAT_CAT: Dictionary[String, Dictionary] = {
 FLINCH = {
  SOUND = preload("res://sounds/fatcat/fatcatflinch.wav")
 }, 
 DEATH = {
  SOUND = preload("res://sounds/fatcat/fatcatdeath.wav"), 
 }, 
 KNEAD = {
  SOUNDS = [
   preload("res://sounds/fatcat/fatcatknead1.wav"), 
   preload("res://sounds/fatcat/fatcatknead2.wav"), 
  ], 
 }, 
 SLURP = {
  SOUNDS = [
   preload("res://sounds/fatcat/fatcatslurp1.wav"), 
   preload("res://sounds/fatcat/fatcatslurp2.wav"), 
  ], 
  CYCLE = true, 
 }, 
}

const URCHIN = {
 SHIELD_LOOP = {
  SOUND = preload("res://sounds/urchin/urchinloop.ogg"), 
  VOLUME = 0.5, 
  STOP_ON_TREE_EXIT = true, 
 }, 
 JUMP = {
  SOUND = preload("res://sounds/urchin/urchinjump.wav"), 
 }, 
 SWING = {
  SOUND = preload("res://sounds/urchin/urchinswing.wav"), 
 }, 
 PSYCH = {
  SOUND = preload("res://sounds/urchin/urchinpsych.wav")
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/urchin/urchinflinch.wav")
 }, 
 FLINCH_WEAK = {
  SOUND = preload("res://sounds/urchin/urchinflinchweak.wav")
 }, 
}

const ELMER = {
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/publicbroadcast/pbhurt1.wav"), 
   preload("res://sounds/publicbroadcast/pbhurt2.wav"), 
   preload("res://sounds/publicbroadcast/pbhurt3.wav"), 
  ], 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/publicbroadcast/pbdie.wav"), 
 }, 
 DEATH_2 = {
  SOUND = preload("res://sounds/publicbroadcast/pbdie2.wav"), 
 }, 
 RIMSHOT = {
  SOUND = preload("res://sounds/publicbroadcast/pbrimshot.wav"), 
 }, 
 SLIDE_WHISTLE = {
  SOUND = preload("res://sounds/publicbroadcast/pbslidewhistle.wav"), 
 }, 
 HEY = {
  SOUND = preload("res://sounds/publicbroadcast/pbhi.wav")
 }, 
 LAUGH = {
  SOUND = preload("res://sounds/publicbroadcast/pblaugh.wav"), 
 }, 
 BOOM_MIC = {
  SOUND = preload("res://sounds/publicbroadcast/pbboommic.wav"), 
  IN_GAME_ONLY = true, 
 }, 
 DIE = {
  SOUND = preload("res://sounds/publicbroadcast/pbdie.wav")
 }, 
 DEBORAH_FLY = {
  SOUND = preload("res://sounds/publicbroadcast/pbfishfall.wav"), 
  IN_GAME_ONLY = true, 
 }, 
 DEBORAH_IMPACT = {
  SOUND = preload("res://sounds/publicbroadcast/pbstinger.wav"), 
  VOLUME = 0.8, 
 }, 
 DEBORAH_THROW = {
  SOUNDS = [
   preload("res://sounds/publicbroadcast/pbthrow1.wav"), 
   preload("res://sounds/publicbroadcast/pbthrow2.wav"), 
  ], 
 }, 
 DEBORAH_PICKUP = {
  SOUNDS = {
   preload("res://sounds/publicbroadcast/pbfishpickup.wav"): 1.0, 
   preload("res://sounds/publicbroadcast/pbpetfish.wav"): 0.1, 
  }, 
 }, 
 SOCK_MUPPER = {
  SOUND = preload("res://sounds/publicbroadcast/sock mupper.wav"), 
 }, 
 LOTD = {
  SOUND = preload("res://sounds/publicbroadcast/pbletteroftheday.wav"), 
 }, 
}

const ANTI_SEX_WORKER = {
 FLINCH = {
  SOUND = preload("res://sounds/antisex/antisexflinch.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/antisex/antisexdeath.wav"), 
 }, 
 CRAMP = {
  SOUNDS = [
   preload("res://sounds/antisex/antisexcramp1.wav"), 
   preload("res://sounds/antisex/antisexcramp2.wav"), 
  ]
 }, 
 TRAITOR_CRAMP = {
  SOUNDS = [
   preload("res://sounds/antisex/traitorcramp1.wav"), 
   preload("res://sounds/antisex/traitorcramp2.wav"), 
  ]
 }, 
 PROTEST = {
  SOUNDS = [
   preload("res://sounds/antisex/antisexprotest1.wav"), 
   preload("res://sounds/antisex/antisexprotest2.wav"), 
  ]
 }, 
 SPURT = {
  SOUND = preload("res://sounds/antisex/antisexspurt.wav"), 
 }, 
}

const SNOWBALL = {
 CACKLE = {
  SOUNDS = [
   preload("res://sounds/snowball/snowballcackle1.wav"), 
   preload("res://sounds/snowball/snowballcackle2.wav"), 
   preload("res://sounds/snowball/snowballcackle3.wav"), 
  ]
 }, 
 INHALE = {
  SOUND = preload("res://sounds/snowball/snowballinhale.wav"), 
 }, 
 EXHALE = {
  SOUND = preload("res://sounds/snowball/snowballexhale.wav"), 
 }, 
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/snowball/snowballflinch1.wav"), 
   preload("res://sounds/snowball/snowballflinch2.wav"), 
  ]
 }, 

 DEATH = {
  SOUND = preload("res://sounds/snowball/snowballdeath.wav"), 
 }, 
}

const PADDLERS = {
 PADDLE = {
  SOUND = preload("res://sounds/paddlers/paddleswing.wav"), 
 }, 
 YURI = {
  SOUNDS = [
   preload("res://sounds/paddlers/yuri1.wav"), 
   preload("res://sounds/paddlers/yuri2.wav"), 
   preload("res://sounds/paddlers/yuri3.wav"), 
  ], 
 }, 
 YURI_HURT = {
  SOUND = preload("res://sounds/paddlers/yurihurt.wav"), 
 }, 
 YAOI = {
  SOUNDS = [
   preload("res://sounds/paddlers/yaoi1.wav"), 
   preload("res://sounds/paddlers/yaoi2.wav"), 
   preload("res://sounds/paddlers/yaoi3.wav"), 
  ], 
 }, 
 YAOI_HURT = {
  SOUND = preload("res://sounds/paddlers/yaoihurt.wav"), 
 }, 
}

const FREEZER = {
 BOUNCE = {
  SOUND = preload("res://sounds/freezer/freezerbounce.wav"), 
  PITCH_VARIANCE = 0.2, 
 }, 
 EXPLODE = {
  SOUND = preload("res://sounds/freezer/freezerexplode.wav"), 
 }, 
 DRUM = {
  SOUNDS = [
   preload("res://sounds/freezer/freezerdrum1.wav"), 
   preload("res://sounds/freezer/freezerdrum2.wav"), 
  ]
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/freezer/freezerflinch.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/freezer/freezerdeath.wav"), 
 }, 
 VOX_FREEZER = {
  SOUNDS = [
   preload("res://sounds/freezer/freezervox1.wav"), 
   preload("res://sounds/freezer/freezervox2.wav"), 
   preload("res://sounds/freezer/freezervox3.wav"), 
  ], 
 }, 
 VOX_FOREIGN_BODY = {
  SOUNDS = [
   preload("res://sounds/freezer/foreign1.wav"), 
   preload("res://sounds/freezer/foreign2.wav"), 
  ], 
 }, 
}

const LIQUID_HUMAN = {
 ATTACK = {
  SOUND = preload("res://sounds/liquidhuman/liquidattack.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/liquidhuman/liquiddeath.wav"), 
 }, 
 DO_NOTHING = {
  SOUND = preload("res://sounds/liquidhuman/liquiddonothing.wav"), 
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/liquidhuman/liquidhit.wav"), 
 }, 
 FLINCH_LETHAL = {
  SOUND = preload("res://sounds/liquidhuman/liquidflinchlethal.wav"), 
 }, 
 IMPACT = {
  SOUND = preload("res://sounds/liquidhuman/liquidimpact.wav"), 
  VOLUME = 0.5, 
 }, 
}

const STRAWMAN = {
 TAP = {
  SOUND = preload("res://sounds/strawman/cutesquishyomg.wav"), 
  STOP_ON_PLAY = true, 
 }, 
 TOUCH_ME = {
  SOUNDS = [
   preload("res://sounds/strawman/touchmeez.wav"), 
   preload("res://sounds/strawman/pweasetouchmee.wav"), 
  ]
 }, 
 DONT_STOP = {
  SOUNDS = [
   preload("res://sounds/strawman/dontstop.wav"), 
   preload("res://sounds/strawman/tapmeagainpls.wav"), 
  ], 
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/strawman/x33.wav"), 
 }, 
 NOBODY_WUBS_ME = {
  SOUND = preload("res://sounds/strawman/nobodywubsme.wav"), 
 }, 
 NOOO_DONT_DO_IT = {
  SOUND = preload("res://sounds/strawman/nooodontdoit.wav"), 
 }, 

 WARNING = {
  SOUND = preload("res://sounds/strawman/STdemo1.wav"), 
 }, 
 INPUT_PASSWORD = {
  SOUND = preload("res://sounds/strawman/STdemo2.wav"), 
 }, 
 INVALID_PASSWORD = {
  SOUND = preload("res://sounds/strawman/STdemo3.wav"), 
 }, 
 WELCOME_USER = {
  SOUND = preload("res://sounds/strawman/STdemo4.wav"), 
 }, 
 TROLL = {
  SOUND = preload("res://sounds/strawman/STenddemo.wav"), 
 }, 
 DEMO_ERROR = {
  SOUND = preload("res://sounds/strawman/STdemoerror.wav"), 
 }, 
 TROUBLESHOOT = {
  SOUND = preload("res://sounds/strawman/STdemotroubleshoot.wav"), 
 }, 
}

const GREEB = {
 FLINCH = {
  SOUND = preload("res://sounds/greeb/greebflinch.wav"), 
 }, 
 FLINCH_FOUCAULT = {
  SOUND = preload("res://sounds/greeb/foucault.wav"), 
 }, 
 DEATH_START = {
  SOUND = preload("res://sounds/greeb/greebdeathstart.wav"), 
 }, 
 DEATH_END = {
  SOUND = preload("res://sounds/greeb/greebdeathend.wav"), 
 }, 
 SCREAM = {
  SOUND = preload("res://sounds/greeb/greebdeathscream.wav"), 
 }, 
 LIGHT = {
  SOUND = preload("res://sounds/greeb/lighter.wav"), 
 }, 
 BUBBLES = {
  SOUND = preload("res://sounds/greeb/bubbles.wav"), 
  PLAY_FROM = 5.0, 
  VOLUME = 0.3, 
 }, 
 SMOKE = {
  SOUND = preload("res://sounds/greeb/greebsmoke.wav")
 }, 
 COUGH = {
  SOUNDS = [
   preload("res://sounds/greeb/greebcough1.wav"), 
   preload("res://sounds/greeb/greebcough2.wav"), 
  ]
 }, 
 TRACTOR_BEAM = {
  SOUND = preload("res://sounds/greeb/greebtractorbeam.wav"), 
  STOP_ON_TREE_EXIT = true, 
 }, 
 LAUGH = {
  SOUND = preload("res://sounds/greeb/greeblaugh.wav"), 
 }, 
 UFO = {
  SOUNDS = [
   preload("res://sounds/greeb/greebufo1.wav"), 
   preload("res://sounds/greeb/greebufo2.wav"), 
   preload("res://sounds/greeb/greebufo3.wav"), 
  ]
 }, 
 SHOOT = {
  SOUND = preload("res://sounds/greeb/greebshoot.wav"), 
  VOLUME = 0.3, 
 }, 
 GROAN = {
  SOUND = preload("res://sounds/greeb/greebgroan.wav"), 
 }, 
 HOVER = {
  SOUND = preload("res://sounds/greeb/greebhover.wav"), 
 }, 
 THERE_HE_GOES = {
  SOUND = preload("res://sounds/greeb/therehegoes.wav"), 
 }, 
 BONG_EXPLODE = {
  SOUND = preload("res://sounds/greeb/greebbongshatter.wav"), 
 }, 
}

const DEW_JUBILIST = {
 FLINCH = {
  SOUND = preload("res://sounds/dewjubilist/dewflinch.wav"), 
 }, 
 THROW = {
  SOUNDS = [
   preload("res://sounds/dewjubilist/dewthrow1.wav"), 
   preload("res://sounds/dewjubilist/dewthrow2.wav"), 
  ], 
 }, 
 THROW_LONG = {
  SOUND = preload("res://sounds/dewjubilist/dewthrowlong.wav"), 
 }, 
 WHOOSH = {
  SOUND = preload("res://sounds/dewjubilist/dewthrowwoosh.wav"), 
 }, 
}

const XRAFSTAR = {
 HOST_FLINCH = {
  SOUND = preload("res://sounds/xrafstar/xrafhostflinch.wav"), 
 }, 
 PARASITE_FLINCH = {
  SOUND = preload("res://sounds/xrafstar/xrafstarparasiteflinch.wav"), 
 }, 
 PARASITE_IN = {
  SOUND = preload("res://sounds/xrafstar/xrafparasitein.wav"), 
 }, 
 PARASITE_OUT = {
  SOUND = preload("res://sounds/xrafstar/xrafparasiteout.wav"), 
 }, 
 PARASITE_APPEAR = {
  SOUND = preload("res://sounds/xrafstar/xrafparasiteappear.wav"), 
 }, 
 PARASITE_ATTACK = {
  SOUND = preload("res://sounds/xrafstar/xrafparasiteattack.wav"), 
 }, 
 HOST_VOMIT = {
  SOUND = preload("res://sounds/xrafstar/xrafhostvomit.wav"), 
 }, 
}

const BRUTALIST = {
 APPEAR = {
  SOUND = preload("res://sounds/brutalist/brutalistapproach.wav"), 
 }, 
 RETREAT = {
  SOUND = preload("res://sounds/brutalist/brutalistretreat.wav"), 
 }, 
 NEXT = {
  SOUND = preload("res://sounds/brutalist/brutalistnext.wav"), 
 }, 
 SPRAWL = {
  SOUND = preload("res://sounds/brutalist/brutalistattack.wav"), 
 }, 
 SUCK = {
  SOUND = preload("res://sounds/brutalist/brutalistsuck.wav"), 
 }, 
 PROCEED = {
  SOUND = preload("res://sounds/brutalist/brutalistproceed.wav"), 
 }, 
 FLINCH_WALL = {
  SOUNDS = [
   preload("res://sounds/brutalist/brutalistflinch1.wav"), 
   preload("res://sounds/brutalist/brutalistflinch2.wav"), 
   preload("res://sounds/brutalist/brutalistflinch3.wav"), 
  ]
 }, 
 CONCRETE = {
  SOUNDS = [
   preload("res://sounds/brutalist/brutalistconcrete1.wav"), 
   preload("res://sounds/brutalist/brutalistconcrete2.wav"), 
   preload("res://sounds/brutalist/brutalistconcrete3.wav"), 
  ]
 }, 
 FLINCH_HEART = {
  SOUNDS = [
   preload("res://sounds/brutalist/heartflinch1.wav"), 
   preload("res://sounds/brutalist/heartflinch2.wav"), 
   preload("res://sounds/brutalist/heartflinch3.wav"), 
  ]
 }, 
 HEART_BEAT = {
  SOUND = preload("res://sounds/brutalist/heartbeat.wav"), 
 }, 
 HEART_BEAT_BIG = {
  SOUND = preload("res://sounds/brutalist/heartbeatbig.wav"), 
 }, 
}


const PRODIGY = {
 FLINCH = {
  SOUND = preload("res://sounds/prodigy/prodigyflinch.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/prodigy/prodigydeath.wav"), 
 }, 
 SHORT = {
  SOUND = preload("res://sounds/prodigy/prodigyshort.wav"), 
 }, 
 LONG = {
  SOUND = preload("res://sounds/prodigy/prodigylong.wav"), 
 }, 
}

const HERARRA = {
 FLINCH = {
  SOUND = preload("res://sounds/herarra/herarraflinch.wav"), 
  VOLUME = 0.8, 
 }, 
 GRUNT = {
  SOUNDS = [
   preload("res://sounds/herarra/herarragrunt1.wav"), 
   preload("res://sounds/herarra/herarragrunt2.wav"), 
   preload("res://sounds/herarra/herarragrunt3.wav"), 
  ], 
  VOLUME = 0.5, 
 }, 
 SPIN = {
  SOUND = preload("res://sounds/herarra/herarraspin.wav"), 
 }, 
}

const PROLE_SERVICE = {
 PICKUP = {
  SOUND = preload("res://sounds/prole/polepickup.wav"), 
 }, 
 LIFT = {
  SOUND = preload("res://sounds/prole/prolelift.wav"), 
 }, 
 ATTACK = {
  SOUND = preload("res://sounds/prole/proleattack.wav"), 
 }, 
 HANG_UP = {
  SOUND = preload("res://sounds/prole/prolehangup.wav"), 
 }, 
 RING = {
  SOUND = preload("res://sounds/prole/prolering.wav"), 
  VOLUME = 0.7, 
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/prole/prolehurt.wav"), 
 }, 
 TONE = {
  SOUNDS = [
   preload("res://sounds/prole/proletone1.wav"), 
   preload("res://sounds/prole/proletone2.wav"), 
   preload("res://sounds/prole/proletone3.wav"), 
   preload("res://sounds/prole/proletone4.wav"), 
  ], 
  STOP_ON_PLAY = true, 
  VOLUME = 0.5, 
 }, 
 JABBER = {
  SOUNDS = [
   preload("res://sounds/prole/prolejabber1.wav"), 
   preload("res://sounds/prole/prolejabber2.wav"), 
   preload("res://sounds/prole/prolejabber3.wav"), 
   preload("res://sounds/prole/prolejabber4.wav"), 
   preload("res://sounds/prole/prolejabber5.wav"), 
   preload("res://sounds/prole/prolejabber6.wav"), 
  ], 
  VOLUME = 0.15, 
 }, 
}

const UMAMI_SOUNDS = {
 FLINCH = {
  SOUND = preload("res://sounds/umami/umamiflinch.wav"), 
 }, 
 CHAIN = {
  SOUND = preload("res://sounds/umami/umamichainloud.wav"), 
  IGNORE_SPRITE_PITCH = true, 
 }, 
 WHINE = {
  SOUND = preload("res://sounds/umami/umamiwhine.wav"), 
 }, 
 WHIP = {
  SOUND = preload("res://sounds/umami/umamiwhip.wav"), 
  IGNORE_SPRITE_PITCH = true, 
 }, 
 ATTACK = {
  SOUND = preload("res://sounds/umami/umamiattack.wav"), 
 }, 
}

const RUBBER_ANIMAL = {
 FLINCH = {
  SOUND = preload("res://sounds/rubberanimal/rubberflinch.wav"), 
 }, 
 FLINCH_BREAK = {
  SOUND = preload("res://sounds/rubberanimal/rubberflinchbreak.wav")
 }, 
 GROWL = {
  SOUND = preload("res://sounds/rubberanimal/rubbergrowl.wav"), 
 }, 
 SPIT = {
  SOUND = preload("res://sounds/rubberanimal/rubberspit.wav"), 
 }, 
 SPIT_BAD = {
  SOUND = preload("res://sounds/rubberanimal/rubberspitbad.wav"), 
 }, 
 LAND = {
  SOUND = preload("res://sounds/rubberanimal/rubberland.wav"), 
 }, 
}

const PARADIGM = {
 BOOM = {
  SOUND = preload("res://sounds/paradigm/paradigmboom.wav"), 
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/paradigm/paradigmflinch.wav"), 
 }, 
 LOB = {
  SOUND = preload("res://sounds/paradigm/paradigmlob.wav"), 
 }, 
 THROW = {
  SOUNDS = [
   preload("res://sounds/paradigm/paradigmthrow1.wav"), 
   preload("res://sounds/paradigm/paradigmthrow2.wav"), 
   preload("res://sounds/paradigm/paradigmthrow3.wav"), 
  ]
 }, 
 COPYCAT_FLEE = {
  SOUND = preload("res://sounds/paradigm/copycatflee.wav"), 
 }, 
 COPYCAT_WIMP_OUT = {
  SOUND = preload("res://sounds/paradigm/copycatwimpout.wav"), 
 }, 
}

const NEW_COP = {
 ENGAGE = {
  SOUND = preload("res://sounds/newcop/newcopentrance.wav"), 
 }, 
 FLINCH = {
  SOUND = preload("res://sounds/newcop/newcopflinch.wav"), 
 }, 
 FLINCH_WEAK = {
  SOUND = preload("res://sounds/newcop/newcopweakflinch.wav"), 
 }, 
 POP = {
  SOUND = preload("res://sounds/newcop/newcoppop.wav"), 
 }, 
 NEW_COP_DAY = {
  SOUND = preload("res://sounds/newcop/newcopdaytomorrow.wav"), 
 }, 
 GUN_COCK = {
  SOUND = preload("res://sounds/newcop/newcopguncock.wav"), 
 }, 
 HOLE_PUNCH = {
  SOUND = preload("res://sounds/newcop/newcopholepunch.wav"), 
 }, 
 WHIFF = {
  SOUND = preload("res://sounds/newcop/newcopwhiff.wav"), 
  VOLUME = 0.7, 
 }, 
 LAUGH = {
  SOUNDS = [
   preload("res://sounds/newcop/newcoplaugh1.wav"), 
   preload("res://sounds/newcop/newcoplaugh2.wav"), 
   preload("res://sounds/newcop/newcoplaugh3.wav"), 
  ]
 }, 
 END_VOMIT = {
  SOUND = preload("res://sounds/newcop/newcopendvomit.wav"), 
 }, 
 VOMIT = {
  SOUND = preload("res://sounds/newcop/newcopvomit.wav"), 
 }, 
 VOMIT_REV = {
  SOUND = preload("res://sounds/newcop/newcopvomitrev.wav"), 
 }, 
 VOMIT_COUGH = {
  SOUND = preload("res://sounds/newcop/newcopvomitcough.wav"), 
 }, 
}

const VAMPIRE = {
 FLINCH = {
  SOUND = preload("res://sounds/vampire/vampireflinch.wav"), 
 }, 
 ATTACK = {
  SOUND = preload("res://sounds/vampire/vampireattack.wav"), 
 }, 
 DRINK = {
  SOUND = preload("res://sounds/vampire/vampiredrink.wav"), 
 }, 
 HISS = {
  SOUND = preload("res://sounds/vampire/vampirehiss.wav"), 
 }, 
 SPLASH = {
  SOUND = preload("res://sounds/vampire/vampiresplash.wav"), 
 }, 
 TELEPORT = {
  SOUND = preload("res://sounds/vampire/vampireteleport.wav"), 
 }, 
}

const AGE_REGRESSOR = {
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/ageregressor/aghurt1.wav"), 
   preload("res://sounds/ageregressor/aghurt2.wav"), 
   preload("res://sounds/ageregressor/aghurt3.wav"), 
  ]
 }, 
 HEAL = {
  SOUND = preload("res://sounds/ageregressor/agheal.wav"), 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/ageregressor/agdeath.wav"), 
 }, 
}

const BAMMON = {
 FLINCH = {
  SOUND = preload("res://sounds/bammon/bammonflinch1.wav"), 
 }, 
 FLINCH_WEIRD = {
  SOUND = preload("res://sounds/bammon/bammonweirdsfx3.wav"), 
 }, 
 OINK = {
  SOUNDS = [
   preload("res://sounds/bammon/bammonentranceoink1.wav"), 
   preload("res://sounds/bammon/bammonentranceoink2.wav"), 
   preload("res://sounds/bammon/bammonentranceoink3.wav"), 
  ], 
 }, 
 ENTRANCE = {
  SOUND = preload("res://sounds/bammon/bammonentrance.wav"), 
 }, 
 BONE_CRACK = {
  SOUND = preload("res://sounds/bammon/bammonbone.wav"), 
 }, 
 BONE_CRACK_TWO = {
  SOUND = preload("res://sounds/bammon/bammonbone.wav"), 
  PITCH_SCALE = 1.2, 
 }, 
 DEATH = {
  SOUND = preload("res://sounds/bammon/bammondeath.wav"), 
 }, 
 FLY_AWAY = {
  SOUND = preload("res://sounds/bammon/bammonflyaway.wav"), 
 }, 
 FLY_AWAY_RETRO = {
  SOUND = preload("res://sounds/bammon/bammonretropull.wav"), 
  VOLUME = 0.3, 
 }, 
 PULL_EFFORT = {
  SOUND = preload("res://sounds/bammon/bammonpulleffort.wav"), 
 }, 
 UNCORK = {
  SOUND = preload("res://sounds/bammon/bammonuncork.wav"), 
 }, 
 LAUNCH_CRIT_START = {
  SOUND = preload("res://sounds/bammon/bammonweirdsfx2.wav"), 
 }, 
 LAUNCH_CRIT = {
  SOUND = preload("res://sounds/bammon/bammonweirdsfx4.wav"), 
 }, 
 ROPE_PULL_SLIDE = {
  SOUND = preload("res://sounds/bammon/bammonweirdsfx1.wav"), 
 }, 
 ROPE_PULL = {
  SOUND = preload("res://sounds/bammon/bammonropepull.wav"), 
 }, 
 ANVIL = {
  SOUND = preload("res://sounds/bammon/bammonanvil.wav"), 
 }, 
 CORK_POP = {
  SOUND = preload("res://sounds/bammon/bammoncorkpop.wav"), 
 }, 
 CORK_CLOSE = {
  SOUND = preload("res://sounds/bammon/bammoncorkclose.wav"), 
 }, 
 GLITTER = {
  SOUND = preload("res://sounds/bammon/bammonglitter.wav"), 
  VOLUME = 0.1, 
 }, 
}

const NOBODY = {
 DEATH = {
  SOUND = preload("res://sounds/nobody/nobodydeath.wav"), 
 }, 
 FLINCH = {
  SOUNDS = [
   preload("res://sounds/nobody/nobodyflinch1.wav"), 
   preload("res://sounds/nobody/nobodyflinch2.wav"), 
   preload("res://sounds/nobody/nobodyflinch3.wav"), 
  ], 
 }, 
 PAPER = {
  SOUNDS = [
   preload("res://sounds/nobody/nobodypaper1.wav"), 
   preload("res://sounds/nobody/nobodypaper2.wav"), 
   preload("res://sounds/nobody/nobodypaper3.wav"), 
  ], 
 }, 
 CHAIR_UP = {
  SOUNDS = [
   preload("res://sounds/nobody/nobodychairup1.wav"), 
   preload("res://sounds/nobody/nobodychairup2.wav"), 
  ]
 }, 
 CHAIR_DOWN = {
  SOUNDS = [
   preload("res://sounds/nobody/nobodychairdown1.wav"), 
   preload("res://sounds/nobody/nobodychairdown2.wav"), 
  ]
 }, 
 CIG = {
  SOUND = preload("res://sounds/nobody/nobodycig.wav"), 
  VOLUME = 0.6, 
 }, 
 CIG_EXTINGUISH = {
  SOUND = preload("res://sounds/nobody/nobodycigextinguish.wav"), 
 }, 
 CIG_FLICK = {
  SOUND = preload("res://sounds/nobody/nobodycigflick.wav"), 
 }, 
}


const SPELLS = {
 SPELL_CLICK = {
  SOUND = preload("res://sounds/ui/paper3.wav"), 
  PITCH_VARIANCE = 0.025, 
 }, 
 PILLS = {
  SOUND = preload("res://sounds/spells/pillbottle.wav"), 
  PITCH_VARIANCE = 0.025, 
  VOLUME = 0.25, 
 }, 
 SALT = {
  SOUND = preload("res://sounds/spells/salt_pillbottle.wav"), 
  PITCH_VARIANCE = 0.025, 
  VOLUME = 0.25, 
 }, 
 GUNSHOT = {
  SOUND = preload("res://sounds/spells/gunshot.wav"), 
  VOLUME = 0.6, 
 }, 
 STAMP = {
  SOUND = preload("res://sounds/spells/stamp.wav"), 
 }, 
 STAMP_BIG = {
  SOUND = preload("res://sounds/spells/stampbig.wav"), 
 }, 
 STAPLE = {
  SOUND = preload("res://sounds/spells/staple.wav"), 
 }, 
 DIAL = {
  SOUND = preload("res://sounds/spells/dial2.wav"), 
 }, 
 DICE_ROLL_1 = {
  SOUND = preload("res://sounds/spells/diceroll1.wav"), 
 }, 
 DICE_ROLL_3 = {
  SOUND = preload("res://sounds/spells/diceroll3.wav"), 
 }, 
 MATCH_BOX = {
  SOUND = preload("res://sounds/spells/matchbox1.wav"), 
 }, 
 SWITCH = {
  SOUND = preload("res://sounds/spells/switch1.wav"), 
 }, 
 MEASURING_TAPE = {
  SOUND = preload("res://sounds/spells/measuringtape.wav"), 
 }, 
 SPRAY_SHORT = {
  SOUND = preload("res://sounds/spells/sprayshort.wav"), 
 }, 
 BOX_SHUFFLE = {
  SOUND = preload("res://sounds/spells/boxshuffle.wav"), 
 }, 
 SODA_CAN = {
  SOUND = preload("res://sounds/spells/can.wav"), 
 }, 
 LIP_BALM = {
  SOUND = preload("res://sounds/spells/chapstick.wav"), 
 }, 
 BOMB_SPAWN = {
  SOUND = preload("res://sounds/spells/bombitemspawm.wav"), 
 }, 
 CLOVER_EAT_A = {
  SOUND = preload("res://sounds/spells/cloverc4a.wav"), 
 }, 
 CLOVER_EAT_B = {
  SOUND = preload("res://sounds/spells/clovereat4.wav"), 
 }, 
 SCREW = {
  SOUND = preload("res://sounds/spells/drill.wav"), 
 }, 
 SCREW_HIGH_PITCH = {
  SOUND = preload("res://sounds/spells/drill.wav"), 
  PITCH_SCALE = 1.2, 
 }, 

}

const NOBODY_MORSE = {
 "a": preload("res://sounds/nobody/morse/a.wav"), 
 "b": preload("res://sounds/nobody/morse/b.wav"), 
 "c": preload("res://sounds/nobody/morse/c.wav"), 
 "d": preload("res://sounds/nobody/morse/d.wav"), 
 "e": preload("res://sounds/nobody/morse/e.wav"), 
 "f": preload("res://sounds/nobody/morse/f.wav"), 
 "g": preload("res://sounds/nobody/morse/g.wav"), 
 "h": preload("res://sounds/nobody/morse/h.wav"), 
 "i": preload("res://sounds/nobody/morse/i.wav"), 
 "j": preload("res://sounds/nobody/morse/j.wav"), 
 "k": preload("res://sounds/nobody/morse/k.wav"), 
 "l": preload("res://sounds/nobody/morse/l.wav"), 
 "m": preload("res://sounds/nobody/morse/m.wav"), 
 "n": preload("res://sounds/nobody/morse/n.wav"), 
 "o": preload("res://sounds/nobody/morse/o.wav"), 
 "p": preload("res://sounds/nobody/morse/p.wav"), 
 "q": preload("res://sounds/nobody/morse/q.wav"), 
 "r": preload("res://sounds/nobody/morse/r.wav"), 
 "s": preload("res://sounds/nobody/morse/s.wav"), 
 "t": preload("res://sounds/nobody/morse/t.wav"), 
 "u": preload("res://sounds/nobody/morse/u.wav"), 
 "v": preload("res://sounds/nobody/morse/v.wav"), 
 "w": preload("res://sounds/nobody/morse/w.wav"), 
 "x": preload("res://sounds/nobody/morse/x.wav"), 
 "y": preload("res://sounds/nobody/morse/y.wav"), 
 "z": preload("res://sounds/nobody/morse/z.wav"), 
}

const STINGERS = {
 ENEMY_DEATH = {
  SOUND = preload("res://music/death_stinger.ogg"), 
  VOLUME = 0.4, 
 }, 
 BOSS_DEATH = {
  SOUND = preload("res://music/boss_death_stinger.ogg"), 
  VOLUME = 0.4
 }, 
 GAME_OVER = {
  SOUND = preload("res://music/gameover.ogg"), 
  VOLUME = 0.3, 
 }, 
 VICTORY = {
  SOUND = preload("res://music/nobody_stinger.ogg"), 
  VOLUME = 0.4, 
 }, 
}

const TileStatus = Globals.TileStatus
const STATUS_SOUNDS = {
 TileStatus.CRIT: TILE.CRIT, 
 TileStatus.POISON: TILE.POISON, 
 TileStatus.COAL: TILE.COAL, 
 TileStatus.SPICY: TILE.BURNING, 
 TileStatus.BLEED: TILE.BLEED, 
 TileStatus.MONEY: TILE.MONEY, 
 TileStatus.CURSED: TILE.CURSED, 
 TileStatus.BRUISE: TILE.BRUISE, 
 TileStatus.FROZEN: TILE.FROZEN, 
 TileStatus.LINKED: TILE.LINKED, 
 TileStatus.POOP: TILE.TARNISHED, 
 TileStatus.CANDY: TILE.CANDY, 
 TileStatus.ASH: TILE.ASH, 
 TileStatus.ETERNAL: TILE.ETERNAL, 
 TileStatus.ACID: TILE.ACID, 
 TileStatus.GUNK: TILE.GUNK, 
}

const CHARACTERS = Globals.CHARACTERS
const CHARACTER_DEATH_SOUNDS = {
 CHARACTERS.LEXICOGRAPHER: LEXICOGRAPHER.DIE, 
 CHARACTERS.FISHER: FISHER.DIE, 
 CHARACTERS.ADDICT: ADDICT.DIE, 
 CHARACTERS.JUBILIST: JUBILIST.DIE, 
 CHARACTERS.CHILD: CHILD.DIE, 
}

const ENEMY_DEATH_SOUNDS: Dictionary[String, Dictionary] = {
 Enemies.CAT: CAT.DEATH, 
 Enemies.BOTTOM_FEEDER: BOTTOM_FEEDER.DEATH, 
 Enemies.STOKER: STOKER.DEATH, 
 Enemies.FAT_CAT: FAT_CAT.DEATH, 
 Enemies.PRODIGY: PRODIGY.DEATH, 
}

static var SOUND_GROUPS: Array[String] = []
static var SOUND_CONSTANTS: Dictionary[String, Dictionary] = {}

static func _static_init() -> void :
 refresh_sounds()


static func refresh_sounds() -> void :
 SOUND_GROUPS.clear()
 SOUND_CONSTANTS.clear()
 var constant_map: Dictionary = Sounds.new().get_script().get_script_constant_map()
 register_sounds(constant_map, SOUND_CONSTANTS, SOUND_GROUPS)


static func register_sounds(dictionary: Dictionary, constants: Dictionary[String, Dictionary], groups: Array[String], group_path: Array[String] = []) -> void :
 var group: String = "/".join(group_path)
 for key: String in dictionary:
  if key.to_lower() == key:
   continue

  var value: Variant = dictionary[key]
  if value is not Dictionary:
   continue

  var path: Array[String] = group_path.duplicate()
  path.append(key)
  if "SOUND" in value or "SOUNDS" in value:
   if group not in groups:
    groups.append(group)

   var sound_name: String = "/".join(path)
   constants[sound_name] = value
  else:
   register_sounds(value, constants, groups, path)


static func validate_sound_property(property: Dictionary, is_groups_property: bool = false, include_groups: = PackedStringArray()) -> void :
 var constant_map: Dictionary = Sounds.new().get_script().get_script_constant_map()
 var constants: Dictionary[String, Dictionary] = {}
 var groups: Array[String] = []
 register_sounds(constant_map, constants, groups)

 var enum_list: = PackedStringArray()
 if is_groups_property:
  enum_list.append_array(groups)
 else:
  enum_list.append("None")
  for sound_key in constants:
   var is_in_sound_group: = true
   if not include_groups.is_empty():
    is_in_sound_group = false
    for group in include_groups:
     if sound_key.begins_with(group):
      is_in_sound_group = true
      break

   if is_in_sound_group:
    enum_list.append(sound_key)

 var enum_hint: = ",".join(enum_list)
 if property.type == TYPE_STRING:
  property.hint_string = enum_hint
 else:
  property.hint_string = "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, enum_hint]
