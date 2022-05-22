class Language
{
  static String locale = "fr";

  // StartScreen
  static Text connexion = Text("Connexion", "Connecting");
  static Text chargementDonnees = Text("Chargement des données", "Loading data");
  static Text nouvellePartie = Text("NOUVELLE PARTIE", "NEW GAME");
  static Text continuer = Text("CONTINUER", "CONTINUE");

  // Works
  static Text work_aucun = Text("Aucun", "None");
  static Text work_attaquer = Text("Attaquer", "Attack");
  static Text work_bandage = Text("Bandage", "Bandage");
  static Text work_soin = Text("Soin %%%mp", "Heal %%%mp");

  // Tutoriel 1
  static Text tutoriel1_phrase1 = Text("Attention !\nUn monstre m'attaque ! Je ferais mieux de réviser ma stratégie de combat.", "Watch out !\nA monster is attacking ! I should check out my combat strategy");
  static Text tutoriel1_pointer1 = Text("Voir ma stratégie", "Check my strategy");
  static Text tutoriel1_phrase2 = Text("Pour l'instant, ma stratégie est plutôt simple :\nATTAQUER LE MONSTRE !", "For now, my strategy is quite simple :\nATTACK THE MONSTER !");
  static Text tutoriel1_pointer2 = Text("Voir le détail", "See details");
  static Text tutoriel1_phrase3 = Text("En détail : \nMa cible, c'est <Ennemi>\nEt l'action, c'est <Attaquer>", "Details of my strategy:\nMy target is <Ennemy>\nMy action is <Attack>");
  static Text tutoriel1_pointer3_1 = Text("Configuration de la cible", "Target configuration");
  static Text tutoriel1_pointer3_2 = Text("Configuration de l'action à effectuer sur la cible", "Action configuration");
  static Text tutoriel1_phrase4 = Text("Plusieurs choix sont possibles,\nmais je vais laisser comme ça pour l'instant.", "There are many choices,\nbut let's keep all this way for now.");

  static Text finDev = Text("FIN DU DEV EN COURS ! MERCI !", "END OF DEVELOPMENT ! THANK YOU !");
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

  String format(dynamic param)
  {
    return str.replaceAll("%%%", param.toString());
  }
}