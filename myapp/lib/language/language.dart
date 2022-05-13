class Language
{
  static String locale = "en";

  // StartScreen
  static Text connexion = Text("Connexion", "Connecting");
  static Text chargementDonnees = Text("Chargement des données", "Loading data");
  static Text nouvellePartie = Text("NOUVELLE PARTIE", "NEW GAME");
  static Text continuer = Text("CONTINUER", "CONTINUE");

  // Tutoriel 1
  static Text tutoriel1_phrase1 = Text("Attention !\nUn monstre m'attaque ! Je ferais mieux de réviser ma stratégie de combat.", "Watch out !\nA monster is attacking ! I should check out my combat strategy");
  static Text tutoriel1_pointer1 = Text("Voir ma stratégie", "Check my strategy");
  static Text tutoriel1_phrase2 = Text("Pour l'instant, ma stratégie est plutôt simple :\nATTAQUER LE MONSTRE !", "For now, my strategy is quite simple :\nATTACK THE MONSTER !");
  static Text tutoriel1_pointer2 = Text("Voir le détail", "See details");
}

class Text
{
  final String fr;
  final String en;
  Text(this.fr, this.en);

  String get str => Language.locale == "fr" ? fr : en;

  @override
  String toString()
  {
    return str;
  }
}