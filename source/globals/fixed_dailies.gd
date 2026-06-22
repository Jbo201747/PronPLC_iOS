class_name FixedDailies extends RefCounted

const CHARACTERS = Globals.CHARACTERS
const SPELLS = Globals.SPELLS

const DAILY_INFO = {

 {year = 2026, month = 6, day = 2}: {
  character = CHARACTERS.JUBILIST, 
  difficulty = 2, 
  shadows = {
   1: false, 
   2: false, 
  }, 
 }, 
 {year = 2026, month = 6, day = 3}: {
  character = CHARACTERS.FISHER, 
  difficulty = 3, 
  shadows = {
   2: false
  }, 
 }, 


 {year = 2026, month = 6, day = 4}: {
  character = CHARACTERS.LEXICOGRAPHER, 
  difficulty = 1, 
  shadows = false, 
 }, 
 {year = 2026, month = 6, day = 5}: {
  character = CHARACTERS.JUBILIST, 
  difficulty = 2, 
  shadows = {
   1: false, 
   2: false, 
  }, 
 }, 
 {year = 2026, month = 6, day = 6}: {
  character = CHARACTERS.FISHER, 
  difficulty = 3, 
  enemies = [Enemies.TRAFFIC, Enemies.SOPPY, Enemies.SOCIAL_CLIMBERS, Enemies.FOREIGN_BODY, Enemies.UFO, Enemies.RECEIVER, Enemies.VAMPIRE], 
  shadows = false, 
 }, 
 {year = 2026, month = 6, day = 7}: {
  character = CHARACTERS.CHILD, 
  difficulty = 2, 
 }, 
 {year = 2026, month = 6, day = 8}: {
  character = CHARACTERS.ADDICT, 
  difficulty = 0, 
 }, 
 {year = 2026, month = 6, day = 9}: {
  character = CHARACTERS.LEXICOGRAPHER, 
  difficulty = 2, 
  shadows = true, 
 }, 
 {year = 2026, month = 6, day = 20}: {
  character = CHARACTERS.LEXICOGRAPHER, 
  difficulty = 1, 
  enemies = [Enemies.MILKWORM, Enemies.HOUSEBROKEN, Enemies.SHERIFF], 
  spells = {
   0: {
    0: [SPELLS.MOOD_SCREW], 
    1: [SPELLS.EXPIRED_RATION], 
   }, 
  }, 
 }, 
}
