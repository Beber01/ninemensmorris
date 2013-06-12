import 'dart:async';
import 'dart:math';
import 'package:web_ui/web_ui.dart';
import 'dart:html';
import 'memory.dart';
import 'mouvement.dart';

class Game extends WebComponent {
  
  static String VIDE = "pion";
  static String JOUEUR = "pion1";
  static String JOUEUR_DEPLACE = "pion1move";  
  static String IA = "pion2";
  static String IA_DEPLACE = "pion2move";
  
  static String MESSAGE_JOUEUR = "Au tour du joueur.";
  static String MESSAGE_JOUEUR_MORRIS = "Le joueur doit retirer un pion de l'adversaire.";
  static String MESSAGE_IA = "Au tour de l'ordinateur.";
  static String MESSAGE_IA_MORRIS = "L'ordinateur doit retirer un pion de l'adversaire.";
  static String MESSAGE_VICTOIRE = "Partie terminée, le joueur remporte la partie.";
  static String MESSAGE_DEFAITE = "Partie terminée, l'ordinateur remporte la partie.";
  static String MESSAGE_NULL = "Partie terminée, égalité.";
  
  String message = MESSAGE_JOUEUR;
  
  int tour = 0;
  int tourLastMorris = 0;
  int nbrPiecesJoueur = 9;
  int nbrPiecesIA = 9;
  
  bool newMorris = false;
  
  TableCellElement cellToMove = null;
  Mouvement mouvementIA = null;
  bool gameOver = false;
  Timer timer;
  
  List lignes = new List();
  TableSectionElement table;
  Memory memory = new Memory();
  
  
  /**
   * Méthode appelée lorsque le joueur click sur l'emplacement d'un pion sur le plateau
   */
  void clickPion(Event e) {
    if (!gameOver && isTourJoueur()) {
      init(e.target);  
      gestionPhases(e.target);
      
      //Ce timer permet de simuler un temps de réflexion de l'IA, sans cela, l'expérience utilisateur peut parraitre déroutante, notament
      //quand le joueur retire un pion à l'IA et que celle-ci décide d'en reposer un au même emplacement
      if (getCellToMove() == null)
        timer = new Timer(new Duration(seconds: 1), gestionPhasesIA);
    }
  }
  
  /**
   * Méthode qui gère l'appel des différentes phases de jeu
   */
  void gestionPhases(TableCellElement cell) {
    //Si lors d'un clic cette variable est à true, alors le clic est destiné à retirer un pion
    if (getMorris() && isTourJoueur() && cell != null)
      retirePionAdverse(cell);
    else if (!getMorris() && tour < 18) 
      phasePose(cell);
    else if (!getMorris() && tour >= 18)
      phaseDeplacement(cell);
  }
  
  /**
   * Méthode qui appel la gestion des phases en spécifiant une cellule à null, utilisé uniquement par le timer
   */
  void gestionPhasesIA() {
    gestionPhases(null);
  }
  
  /**
   * Gère toute la phase de pose des pions sur le plateau
   */
  void phasePose(TableCellElement cell) {
    
    if (isTourJoueur()) {
      if (cell != null) {
      //Cas où l'on pose un pion, la cellule doit donc être vide
        if (getCellClass(cell) == VIDE) {
          posePion(cell);
          if (getMorris())
            return;
        } else
          return;
      }
    } else {
      posePionIA();
      if (getMorris())
        timer = new Timer(new Duration(seconds: 1), retirePionIAPhasePose);
    }
  } 
  
  /**
   * Gère toute la phase de déplacement des pions sur le plateau
   */
  void phaseDeplacement(TableCellElement cell) {
    if (isTourJoueur()) {
      if (nbrPiecesJoueur > 3) {
        if (getCellToMove() == null && cell != null && getCellClass(cell) == JOUEUR)
          setCellToMove(cell);
        else if (cell != null && getCellClass(cell) == VIDE) {
          deplacePion(cell);
          if (getMorris())
            return; 
        }
        else 
          annuleDeplacement(); 
      } else
        phaseFly(cell);
    } else {
      if (nbrPiecesIA > 3 && nbrPiecesJoueur > 3)
        deplacePionIA();
      else if (nbrPiecesIA > 3 && nbrPiecesJoueur == 3)
        deplacePionIAJoueurFly();
      else if (nbrPiecesIA == 3 && nbrPiecesJoueur > 3)
        flyPionIA();
      else if (nbrPiecesIA == 3 && nbrPiecesJoueur == 3)
        flyPionIAEtJoueurFly();
      else
        phaseFinDePartie(false);
    }
  }
  
  /**
   * Gère toute la phase de déplacement en fly des pions sur le plateau
   */
  void phaseFly(TableCellElement cell) {
    if (isTourJoueur()) {
      if (getCellToMove() == null && cell != null && getCellClass(cell) == JOUEUR)
        setCellToMove(cell);
      else if (cell != null && getCellClass(cell) == VIDE) {
        flyPion(cell);
        if (getMorris())
          return; 
      }
      else 
        annuleDeplacement(); 
    }
  }
   
  /**
   * Gestion de toute la phase de fin de partie
   */
  void phaseFinDePartie(bool bloque) {
    if (bloque) {
      if (isTourJoueur())
        message = MESSAGE_DEFAITE;
      else
        message = MESSAGE_VICTOIRE;
      gameOver = true;
    } else if (nbrPiecesIA < 3) {
      message = MESSAGE_VICTOIRE;
      gameOver = true;
    } else if (nbrPiecesJoueur < 3) {
      message = MESSAGE_DEFAITE;
      gameOver = true;
    } else if (nbrPiecesIA == 3 && nbrPiecesJoueur == 3 && tour - tourLastMorris > 10) {
      message = MESSAGE_NULL;
      gameOver = true;
    } else if (tour - tourLastMorris > 50) {
      message = MESSAGE_NULL;
      gameOver = true;
    } else if (memory.threeTimesSameTable()) {
      message = MESSAGE_NULL;
      gameOver = true;
    }
  }
  
  
  
  
  
  /**
   * Pose un pion sur le plateau
   */
  void posePion(TableCellElement cell) {
    if (getCellClass(cell) == VIDE) {
      if (isTourJoueur())
        setCellClass(cell, JOUEUR);
      else
        setCellClass(cell, IA);

      gestionPhaseMorris(cell);
    }
  }
  
  /**
   * Gère le passage en phase de moulin
   */
  void gestionPhaseMorris(TableCellElement cell) {
    if (cell != null) {
      List lignesModifiees = getLignesFromCell(cell);
      for(List ligne in lignesModifiees) 
        if(testMorris(ligne))
          setMorris(true);
        
      //Si il n'y a pas de nouveau moulin, alors ce tour est terminé
      if (!getMorris())
        tourSuivant();
      //On test si l'on peut retirer un élément (si toutes les pièces adverses ne sont pas dans des moulins), sinon on termine le tour
      else {
        String type = JOUEUR;
        if (isTourJoueur())
          type = IA;
        if (!isAElementOutOfMorris(type)) {
          setMorris(false);
          tourSuivant();
        }
      }
      
    }
  }
  
  /**
   * Retire un pion apartenant à l'adversaire du plateau
   */
  void retirePionAdverse(TableCellElement cell) {
    
    //On test si la cellule ne fait pas partie d'un moulins
    bool morris = false;
    for(List ligne in getLignesFromCell(cell)) {
      if (testMorris(ligne))
        morris = true;
    }
    
    if (!morris) {
      //Si ces conditions sont respectées, alors la cellule désignée n'est pas bonne
      if (isTourJoueur()) {
        if (getCellClass(cell) != IA)
          return;
        else
          enlevePion();
      } else {
        if (getCellClass(cell) != JOUEUR)
          return;
        else
          enlevePion();
      }

      setCellClass(cell, VIDE);
      
      setMorris(false);
      //Comme il y a eu nouveau moulins, le tour n'avait pas été marqué comme terminé
      tourSuivant();
    }
  }
  
  /**
   * Gère le déplacement d'un pion
   */
  void deplacePion(TableCellElement cellNewPosition) {

    if (cellNewPosition != null && getCellClass(cellNewPosition) == VIDE && getCellToMove() != null) {
      List ligne = onSameLine(getCellToMove(), cellNewPosition);
      if (ligne != null && areNeighbor(ligne, getCellToMove(), cellNewPosition)) {
        
        if (isTourJoueur() && getCellClass(getCellToMove()) == JOUEUR_DEPLACE) {
          
          setCellClass(getCellToMove(), VIDE);
          setCellToMove(null);
          setCellClass(cellNewPosition, JOUEUR);
          gestionPhaseMorris(cellNewPosition);
          
        } else if (getCellClass(getCellToMove()) == IA_DEPLACE) {
          
          setCellClass(getCellToMove(), VIDE);
          setCellToMove(null);
          setCellClass(cellNewPosition, IA);
          gestionPhaseMorris(cellNewPosition);
        } else {
          annuleDeplacement();
        }
      } else
        annuleDeplacement();
    } else 
      annuleDeplacement();
  }
  
  /**
   * Gère le fly d'un pion
   */
  void flyPion(TableCellElement cellNewPosition) {
    if (cellNewPosition != null && getCellClass(cellNewPosition) == VIDE && getCellToMove() != null) {
        
      if (isTourJoueur() && getCellClass(getCellToMove()) == JOUEUR_DEPLACE) {
        setCellClass(getCellToMove(), VIDE);
        setCellToMove(null);
        setCellClass(cellNewPosition, JOUEUR);
        gestionPhaseMorris(cellNewPosition);
        
      } else if (getCellClass(getCellToMove()) == IA_DEPLACE) {
        
        setCellClass(getCellToMove(), VIDE);
        setCellToMove(null);
        setCellClass(cellNewPosition, IA);
        gestionPhaseMorris(cellNewPosition);
      } else {
        annuleDeplacement();
      }
    } else 
      annuleDeplacement();
  }
  
  /**
   * Annule la sélection de la pièce à déplacer
   */
  void annuleDeplacement() {
    if (getCellToMove() != null && isTourJoueur()) {
      setCellClass(getCellToMove(), JOUEUR);
      
      setCellToMove(null);
    } else if (getCellToMove() != null && !isTourJoueur()) {
      setMouvementIA(null);
      
      for (int i = 1; i < 25; i++) {
        var cell = getCell(i);
        if (getCellClass(cell) == IA_DEPLACE)
          setCellClass(cell, IA);
      }
      
      phaseDeplacement(null);
    }
  }
  
  
  
  
  
  /**
   * Algorithme de l'IA pour poser ses nouveaux pions
   */
  void posePionIA() {
  
    List possibilitesJoueurAngle = new List();
    List possibilitesJoueurMorris = new List();
    List possibilitesIACreeLigne = new List();
    List possibilitesIAangle = new List();
    List possibilitesIAMorris = new List();
  
    //Première partie (défensive) : on détermine les ligne qui peuvent être complètées par le joueur
    possibilitesJoueurMorris = posePionIA_MorrisPossibilites(JOUEUR);
      
    //Deuxième partie (défensive) : on détermine les angles qui peuvent être pris par le joueur
    possibilitesJoueurAngle = posePionIA_AnglePossibilites(JOUEUR);
    
    //Troisième partie (offensive) : on détermine si l'on a des lignes avec deux éléments IA et un élément vide
    possibilitesIAMorris = posePionIA_MorrisPossibilites(IA);
      
    //Quatrième partie (offensive) : on détermine si une ligne a un élément de l'IA et aucun du joueur
    possibilitesIACreeLigne = posePionIA_LignePossibilites(IA);
    
    //Cinquième partie (offensive) : on détermine si deux lignes avec un élément commun vide ont au moins un pion IA chacun et aucun pion joueur
    possibilitesIAangle = posePionIA_AnglePossibilites(IA);
    
    //Sixième partie de l'algorithme : on détermine sur quel case poser le pion
    //Priorité de sélection : possibilitesIAMorris > possibilitesJoueurMorris > possibilitesIAangle > possibilitesJoueurAngle > possibilitesJoueurCreeLigne
    List possibilitesRetenues = new List();
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesIAMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesIAangle);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurAngle);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesIACreeLigne);

    //On récupère les cellules les plus souvent référencées
    List possibilitesFinal = getMostRefferenced(possibilitesRetenues);
    
    var emptyCell = getRandomElement(possibilitesFinal);
      
    //Cas où l'ensemble de nos tests n'ont retenu aucune position (premier tour IA par exemple), on place alors de manière aléatoire
    if (possibilitesFinal.length == 0 || emptyCell == null) {
      var r = new Random();
      do {
        int i;
        do {
          i = r.nextInt(24);
        } while(i < 1 && i > 24);
        emptyCell = getCell(i);
      } while(emptyCell != null && getCellClass(emptyCell) != VIDE);
    }
    
    posePion(emptyCell);
    
  }
  
  /**
   * on détermine si l'on a des lignes avec deux éléments du type spécifié et un élément vide
   */
  List posePionIA_MorrisPossibilites(String type) {
    var emptyCell;
    List possibilitesIAMorris = new List();
    for(List ligne in lignes) {
      int vide = 0;
      int ia = 0;
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == VIDE) {
          vide++;
          emptyCell = cell;
        }
        else if (getCellClass(cell) == type)
          ia++;
      }
      
      if (vide == 1 && ia == 2)
        possibilitesIAMorris.add(emptyCell);
    }
    return possibilitesIAMorris;
  }
  
  /**
   * on détermine si une ligne a un élément de l'IA et aucun du joueur
   */
  List posePionIA_LignePossibilites(String type) {
    List possibilitesJoueurCreeLigne = new List();
    for(List ligne in lignes) {
      int counterType = 0;
      int counterVide = 0;
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == VIDE)
          counterVide++;
        if (getCellClass(cell) == type)
          counterType++;
      }
      if (counterType == 1 && counterVide == 2) {
        for(TableCellElement cell in ligne) {
          if (getCellClass(cell) == VIDE)
            possibilitesJoueurCreeLigne.add(cell);
        }
      }
    }
    return possibilitesJoueurCreeLigne;
  }
  
  /**
   * on détermine si deux lignes avec un élément commun vide
   * ont au moins un pion IA chacun et aucun pion joueur
   */
  List posePionIA_AnglePossibilites(String type) {
    List possibilitesIAangle = new List();
    for(List ligne1 in lignes) {
      for(List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null && getCellClass(commun) == VIDE){
          bool l1IA = ligneAElementExceptCommun(ligne1, commun, type);
          bool l2IA = ligneAElementExceptCommun(ligne2, commun, type);
          
          if (l1IA && l2IA)
            possibilitesIAangle.add(commun);
        }
      }
    }
    return possibilitesIAangle;
  }

  
  
  
  
  /**
   * Gère la startégie de l'IA pour retirer un pion du joueur pendant la phase de pose
   */
  void retirePionIAPhasePose() {
    List possibilites = new List();
    List possibilitesJoueurAngle = new List();
    List possibilitesJoueurMorris = new List();
    List possibilitesJoueurCreeAngle = new List();
    List possibilitesIAangle = new List();
    List possibilitesIAMorris = new List();
    
    //Première partie : on référence une fois tous les pions du joueur qui ne sont pas dans des moulins
    possibilites = retirePionIA_ReferenceJoueur();
    
    //Deuxième partie (défensive) : on test tous les moulins potentiels (un pion vide et deux pions joueurs)
    possibilitesJoueurMorris = retirePionIAPhasePose_JoueurMoulinsPossibitites(possibilites);
    
    //Troisième partie (défensive) : on détermine les angles potentiels du joueur
    for(List ligne1 in lignes) {
      for(List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null) {
          //Si chaque ligne possède au moins un élément du joueur, aucun de l'IA et rien à la cellule commune
          if (anglePossibleJoueur(ligne1, ligne2, commun)) {
            for (TableCellElement cell in ligne1) {
              //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
              if (possibilites.contains(cell))
                possibilitesJoueurCreeAngle.add(cell);
            }
            for (TableCellElement cell in ligne2) {
              //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
              if (possibilites.contains(cell))
                possibilitesJoueurCreeAngle.add(cell);
            }
          }
          
          //Si l'élément commun est occupé par le joueur, que celui-ci possède un autre élément sur une ligne, et qu'il n'y a aucun élément de l'IA
          if (getCellClass(commun) == JOUEUR) {
            if (moulinPossibleJoueur(ligne1)) {
              for (TableCellElement cell in ligne1) {
                //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
                if (possibilites.contains(cell))
                  possibilitesJoueurAngle.add(cell);
              }
            }
            if (moulinPossibleJoueur(ligne2)) {
              for (TableCellElement cell in ligne2) {
                //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
                if (possibilites.contains(cell))
                  possibilitesJoueurAngle.add(cell);
              }
            }
          }
        }
      }
    }
    
    //Quatrième partie (offensive) : on détermine quelles lignes peuvent êtres remplies en retirant un pion du joueur
    possibilitesIAMorris = retirePionIAPhasePose_MorrisPossibilites(possibilites);
    
    //Cinquième partie (offensive) : on détermine quels angle peuvent êtres utiles pour l'IA (commun au joueur et autres vide ou à l'IA)
    possibilitesIAangle = retirePionIAPhasePose_AnglePossibilites(possibilites);
    
    //Sixième partie : choix du pion à retirer : possibilitesJoueurMorris > possibilitesIAMorris > possibilitesJoueurAngle > possibilitesIAangle > possibilitesJouerCreeAngle
    List possibilitesRetenues = new List();
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesIAMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurAngle);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesIAangle);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurCreeAngle);
    
    if (possibilitesRetenues.length > 0) {
      List cells = getMostRefferenced(possibilitesRetenues);
      TableCellElement cell = getRandomElement(cells); 
      retirePionAdverse(cell);
    } else if(possibilites.length > 0) {
      TableCellElement cell = getRandomElement(possibilites);
      retirePionAdverse(cell);
    } else {
      setMorris(false);
      tourSuivant();
    }
  }
  
  /**
   * on test tous les moulins potentiels (un pion vide et deux pions joueurs)
   */
  List retirePionIAPhasePose_JoueurMoulinsPossibitites(List possibilites) {
    List possibilitesJoueurMorris = new List();
    for(List ligne in lignes) {
      if (moulinPossibleJoueur(ligne)) {
        for (TableCellElement cell in ligne) {
          //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
          if (possibilites.contains(cell))
            possibilitesJoueurMorris.add(cell);
        }
      }
    }
    return possibilitesJoueurMorris;
  }
  
  /**
   * on détermine quelles lignes peuvent êtres remplies en retirant un pion du joueur
   */
  List retirePionIAPhasePose_MorrisPossibilites(List possibilites) {
    List possibilitesIAMorris = new List();
    for(List ligne in lignes) {
      int ia = 0;
      int joueur = 0;
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == IA)
          ia++;
        if (getCellClass(cell) == JOUEUR)
          joueur++;
      }
      
      if (joueur == 1 && ia == 2) {
        for (TableCellElement cell in ligne) {
          //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
          if (possibilites.contains(cell))
            possibilitesIAMorris.add(cell);
        }
      }
    }
    return possibilitesIAMorris;
  }
  
  /**
   * on détermine quels angle peuvent êtres utiles pour l'IA (commun au joueur et autres vide ou à l'IA)
   */
  List retirePionIAPhasePose_AnglePossibilites(List possibilites) {
    List possibilitesIAangle = new List();
    for (List ligne1 in lignes) {
      for (List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null) {
          if(getCellClass(commun) == JOUEUR) {
            if (ligneAElementExceptCommun(ligne1, commun, IA) && ligneAElementExceptCommun(ligne2, commun, IA)) {
              for (TableCellElement cell in ligne1) {
                //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
                if (possibilites.contains(cell))
                  possibilitesIAangle.add(cell);
              }
              
              for (TableCellElement cell in ligne2) {
                //on veille ici à n'ajouter que des cellules déja référencées comme appartenant au joueur et n'intégrant pas un moulins
                if (possibilites.contains(cell))
                  possibilitesIAangle.add(cell);
              }
            }
          }
        }
      }
      return possibilitesIAangle;
    }
  }
  
  
  
  
  
  /**
   * Gère la stratégie de déplacement des pions de l'IA avec les déplacement du joueur normaux
   */
  void deplacePionIA() {
    
    List possibilites = new List();
    List possibilitesJoueur = new List();
    List possibilitesMoulinIA = new List();
    List possibilitesMoulinJoueur = new List();
    List possibilitesBreakMoulinIA = new List();
    List possibilitesPrepareMorris2tours = new List();
    List possibilitesPrepareMorris3tours = new List();
    List possibilitesBloqueMoulinsJoueur = new List();
    List bloqueDejaMoulin = new List();
    List bloqueJoueur = new List();
    List possibilitesBlockBreakMorrisJoueur = new List();
    bool playerCanMakeMorris = false;

    //Première partie : on détermine tous les pions pouvant être déplacés par l'IA et le Joueur
    possibilites = deplacePionIA_ReferenceIAMouvements(IA);
    if (possibilites.length == 0)
      possibilites = deplacePionIA_ReferenceIAMouvements(IA);
    possibilitesJoueur = deplacePionIA_ReferenceIAMouvements(JOUEUR);
    
    //Deuxième partie : On détermine si le joueur peut créer un moulin au prochain tour : 
    // deux lignes avec élement commun vide, une ligne avec deux éléments joueurs et une autre avec un élément joueur voisin du commun
    playerCanMakeMorris = deplacePionIA_JoueurMorrisPossibilites(possibilites);
    
    //Troisième partie : On détermine si l'IA est en mesure de créer un moulin (mêmes conditions, mais testé uniquement sur les mouvements réalisables)
    possibilitesMoulinIA = deplacePionIA_MorrisPossibilites(possibilites);
    
    //Quatrième partie : on détermine si on peut bloquer un moulin potentiel du joueur
    if (playerCanMakeMorris) {
      possibilitesMoulinJoueur = deplacePionIA_BlockJoueurMorrisPossibilites(possibilites);
    }
    
    //Cinquième partie : on détermine si l'on peut défaire un moulin en vue de le refaire, ceci en étant sur de ne pas se faire bloquer ou détruire
    possibilitesBreakMoulinIA = deplacePionIA_BreakMorrisPossibilites(possibilites);
    
    //Sixième partie : on détermine si un pion bloque un moulin potentiel, auquel cas on ne le bouge pas
    bloqueDejaMoulin = deplacePionIA_BlockJoueurMorris(possibilites);
    
    //Septième partie : on cherche à bloquer les mouvements du joueur
    bloqueJoueur = deplacePionIA_BlockJoueurMovPossibilites(possibilites, possibilitesJoueur);
    
    //Huitième partie : on cherche les coups permettant de mettre en situation de créer un moulin (autres que défaire pour refaire)
    for (Mouvement mouvement in possibilites) {
      
      //cas 1: deux lignes avec un élément commun vide, une ligne avec 2 éléments IA et l'autre avec un qui nécessite 2 déplacements pour créer le moulin
      List ligne1 = getLigneFromCells(mouvement.getArrive(), mouvement.getDepart());
      TableCellElement commun;
      for (TableCellElement cell in ligne1) {
        if (cell != mouvement.getDepart() && cell != mouvement.getArrive())
          commun = cell;
      }
      
      //Si l'élément de la ligne non impliqué est vide alors la suite du traitement est pertiante
      if (getCellClass(commun) == VIDE && areNeighbor(ligne1, mouvement.getArrive(), commun)) {
        var lignesCell = getLignesFromCell(commun);
        List ligne2;
        for(List ligne in lignesCell) {
          if (ligne != ligne1)
            ligne2 = ligne;
        }
        
        int IACount = 0;
        for(TableCellElement cell in ligne2) {
          if (cell != commun && getCellClass(cell) == IA) 
            IACount++;
        }
        
        if (IACount++ == 2 && !possibilitesPrepareMorris2tours.contains(mouvement))
          possibilitesPrepareMorris2tours.add(mouvement);
      }
          
          
      //cas 2 : Une ligne avec 1 élément IA, les deux éléments vides peuvent chacun être occupé par l'IA en un coup
      commun = mouvement.getArrive();
      var lignesCell = getLignesFromCell(commun);
      List ligne2;
      for(List ligne in lignesCell) {
        if (ligne != ligne1)
          ligne2 = ligne;
      }
      
      int IACount = 0;
      int videCount = 0;
      TableCellElement cellVide;
      
      for(TableCellElement cell in ligne2) {
        if (getCellClass(cell) == VIDE) {
          videCount++;
          if (cell != commun)
            cellVide = cell;
        } else if (getCellClass(cell) == IA)
          IACount++;
      }
      
      //Si l'on a un élément de l'IA et deux éléments vide dans la ligne2, alors la suite du test est pertinante
      if (videCount == 2 && IACount == 1) {
        //On test alors si la ligne3 possède un pion en mesure d'être posé au tour suivant sur la ligne2
        lignesCell = getLignesFromCell(cellVide);
        List ligne3;
        for(List ligne in lignesCell) {
          if (ligne != ligne2)
            ligne3 = ligne;
        }
        
        //Ici on résout le cas énoncé
        for(Mouvement mov2 in possibilites) {
          if (ligne3.contains(mov2.getArrive()) && ligne3.contains(mov2.getDepart()) && mov2.getArrive() == cellVide) {
            if (!possibilitesPrepareMorris2tours.contains(mouvement))
              possibilitesPrepareMorris2tours.add(mouvement);
          } else if (ligne3.contains(mov2.getArrive()) && ligne3.contains(mov2.getDepart()) && mov2.getArrive() != cellVide) {
            //Cas où le second nécessite deux déplacement : ligne3 a un élément IA et deux élément vides
            if (areNeighbor(ligne3, cellVide, mov2.getArrive()) && !possibilitesPrepareMorris3tours.contains(mouvement))
              possibilitesPrepareMorris3tours.add(mouvement);
          }
        }
      }      
      
      //cas 3 : deux lignes coupées par une même ligne, les intersections sont vides, une contient 2 éléments IA, 
      //l'autre a un besoin d'un déplacement pour s'installer sur la ligne commune -> créé position de moulin ou cas 1
      lignesCell = getLignesFromCell(mouvement.getArrive());
      for(List ligne in lignesCell) {
        if (ligne != ligne1)
          ligne2 = ligne;
      }
      
      for(TableCellElement cell in ligne2) {
        if (cell != mouvement.getArrive() && getCellClass(cell) == VIDE) {
          
          List ligne3;
          lignesCell = getLignesFromCell(cell);
          for(List ligne in lignesCell) {
            if (ligne != ligne2) 
              ligne3 = ligne;
          }
          
          int IACount = 0;
          for(TableCellElement cell in ligne3) {
            if(getCellClass(cell) == IA)
              IACount++;
          }
          
          //La ligne voisine (parallèle au déplacement) contient deux éléments de l'IA, la suite du test a alors un intéret
          if(IACount == 2) {
            //Cas où les deux lignes sont voisines
            if (areNeighbor(ligne2, cell, mouvement.getArrive())) {
              if (possibilitesPrepareMorris2tours.contains(mouvement))
                possibilitesPrepareMorris2tours.add(mouvement);
            }
            
            //Cas où il y a une ligne lambda entre les deux lignes à traiter
            if (!areNeighbor(ligne2, cell, mouvement.getArrive())) {
              int videCount = 0;
              for (TableCellElement cell in ligne2) {
                if (getCellClass(cell) == VIDE)
                  videCount++;
              }
              if (videCount == 3) {
                if (possibilitesPrepareMorris3tours.contains(mouvement))
                  possibilitesPrepareMorris3tours.add(mouvement);
              }
            }
          }
        }
      }
      
      //cas 4 : la remontée d'angle -> deux lignes avec trois éléments de l'IA dont le commun, on déplace les éléments de sorte à créer un des autres cas
      ligne1 = getLigneFromCells(mouvement.getDepart(), mouvement.getArrive());
      IACount = 0;
      videCount = 0;
      TableCellElement cell3;
      for(TableCellElement cell in ligne1) {
        if (getCellClass(cell) == IA) {
          IACount++;
          if (cell != mouvement.getDepart())
            cell3 = cell;
        }
        if (getCellClass(cell) == VIDE)
          videCount++;
      }
      
      //Cas où la suite du test est pertinante
      if (IACount == 2 && videCount == 1) {
        lignesCell = getLignesFromCell(mouvement.getDepart());
        for(List ligne in lignesCell) {
          if (ligne != ligne1)
            ligne2 = ligne;
        }
        
        //Cas où la cellule vide est au milieu d'une ligne
        for(TableCellElement cell in ligne2) {
          if (getCellClass(cell) == IA && cell != mouvement.getDepart()) {
            //la création d'un moulins peut ce faire en deux tours
            if (areNeighbor(ligne2, cell, mouvement.getDepart())) {
              if (possibilitesPrepareMorris2tours.contains(mouvement))
                possibilitesPrepareMorris2tours.add(mouvement);
            }
            
            if (!areNeighbor(ligne2, cell, mouvement.getDepart())) {
              cellVide = null;
              for (TableCellElement c in ligne2) {
                if (getCellClass(c) == VIDE)
                  cellVide = c;
              }
              
              //la création d'un moulins peut ce faire en trois tours
              if (cellVide != null && possibilitesPrepareMorris3tours.contains(mouvement)) {
                possibilitesPrepareMorris3tours.add(mouvement);
              }
            }
          }
        }
        
        //Cas où la cellule vide est à l'extrémité d'une ligne
        lignesCell = getLignesFromCell(cell3);
        for(List ligne in lignesCell) {
          if (ligne != ligne1)
            ligne2 = ligne;
        }
        
        for(TableCellElement cell in ligne2) {
          if (getCellClass(cell) == IA && cell != cell3) {
            if (areNeighbor(ligne2, cell, cell3)) {
              if (possibilitesPrepareMorris3tours.contains(mouvement))
                possibilitesPrepareMorris3tours.add(mouvement);
            }
          }
        }
      }
    }
    
    //Neuvième partie : on détermine quels mouvements il ne vaut mieux pas exécuter car si le joueur bouge la mauvaise pièce alors son moulins peut être bloqué
    possibilitesBloqueMoulinsJoueur = deplacePionIA_WaitBlockMorrisPossibilites(possibilites);
    
    //Dixièmre partie : on détermine si on peut bloqué la destruction d'un moulin du joueur pour l'empêcher de le reconstruire
    possibilitesBlockBreakMorrisJoueur = deplacePionIA_BlockBreakMorrisPossibilites(possibilites);
    
    //Dernière partie : choix du mouvement, priotités : possibilitesMoulinIA > possibilitesMoulinJoueur > possibilitesBreakMoulinIA > bloqueJoueur > possibilitesPrepareMorris2tours > possibilitesPrepareMorris3tours
    List possibilitesRetenues = new List();
    //On retire des mouvements à ne pas exécuter car bloque moulins joueur ceux qui peuvent permettre à l'IA de réaliser un moulin
    bloqueDejaMoulin = removeElementsRefferenced(bloqueDejaMoulin, possibilitesMoulinIA);
    possibilitesBreakMoulinIA = removeElementsRefferenced(possibilitesBreakMoulinIA, possibilitesMoulinIA);
    possibilitesBloqueMoulinsJoueur = removeElementsRefferenced(possibilitesBloqueMoulinsJoueur, possibilitesMoulinIA);
    possibilitesBlockBreakMorrisJoueur = removeElementsRefferenced(possibilitesBlockBreakMorrisJoueur, possibilitesMoulinIA);
    
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMoulinIA);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMoulinJoueur);
    if (!playerCanMakeMorris)
      possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesBreakMoulinIA);
    bloqueDejaMoulin = removeElementsRefferenced(bloqueDejaMoulin, possibilitesMoulinIA);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesBlockBreakMorrisJoueur);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesPrepareMorris2tours);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesPrepareMorris3tours);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, bloqueJoueur);
    //On retire les possibilités qui bloques déjà un moulin
    possibilitesRetenues = removeElementsRefferenced(possibilitesRetenues, bloqueDejaMoulin); 
    if (playerCanMakeMorris)
      possibilitesRetenues = removeElementsRefferenced(possibilitesRetenues, possibilitesBreakMoulinIA);
    
    List possibilitesFinales = getMostRefferenced(possibilitesRetenues);
    
    setMouvementIA(getRandomElement(possibilitesFinales));
    if (possibilites.length > 0 && possibilitesFinales.length == 0 && getMouvementIA() == null)
      setMouvementIA(getRandomElement(possibilites));
    
    if (possibilites.length == 0) {
      phaseFinDePartie(true);
    } else {
      timer = new Timer(new Duration(seconds: 1), deplacePionIADelay);
    }
  }
  
  /**
   * Retourne une liste qui références tous les mouvements du type spécifié
   */
  List deplacePionIA_ReferenceIAMouvements(String type) {
    List possibilites = new List();
    for(List ligne in lignes) {
      for (TableCellElement cell in ligne) {
        if (getCellClass(cell) == type) {
          for (TableCellElement c in getFreeNeighbor(cell)) {
           int count = 0;
           for (Mouvement mouvement in possibilites) {
             if (mouvement.getDepart() == cell && mouvement.getArrive() == c)
               count++;
           }
           if (count == 0)
             possibilites.add(new Mouvement(cell, c));
          }
        }
      }
    }
    return possibilites;
  }
  
  /**
   * On détermine si le joueur peut créer un moulin au prochain tour : 
   * deux lignes avec élement commun vide, une ligne avec deux éléments joueurs et une autre avec un élément joueur voisin du commun
   */
  bool deplacePionIA_JoueurMorrisPossibilites(List possibilites) {
    var playerCanMakeMorris = false;
    for(List ligne1 in lignes) {
      for(List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null && getCellClass(commun) == VIDE) {
          int joueur1 = 0;
          int joueur2 = 0;
          TableCellElement c1 = null;
          TableCellElement c2 = null;
          
          //On compte le nombre d'élements du joueur dans chaque ligne
          for(TableCellElement cell in ligne1) {
            if (getCellClass(cell) == JOUEUR) {
              joueur1++;
              c1 = cell;
            }
          }
          
          for(TableCellElement cell in ligne2) {
            if (getCellClass(cell) == JOUEUR) {
              joueur2++;
              c2 = cell;
            }
          }
          
          //Si une ligne contient deux pièces du joueur et l'autre une, on détermine si la pièce isolée est voisine de l'élément commun
          if (joueur1 == 2 && joueur2 == 1) {
            if (areNeighbor(ligne2, commun, c2))
              playerCanMakeMorris = true;
          }
          
          if (joueur1 == 1 && joueur2 == 2) {
            if (areNeighbor(ligne1, commun, c1))
              playerCanMakeMorris = true;
          }
        }
      }
    }
    
    return playerCanMakeMorris;
  }
  
  /**
   * On détermine si l'IA est en mesure de créer un moulin (mêmes conditions, mais testé uniquement sur les mouvements réalisables)
   */
  List deplacePionIA_MorrisPossibilites(List possibilites) {
    List possibilitesMoulinIA = new List();
    for(Mouvement mouvement in possibilites) {
      List cellLignes = getLignesFromCell(mouvement.getArrive());
      for(List ligne in cellLignes) {
        int count = 0;
        for(TableCellElement cell in ligne) {
          if (getCellClass(cell) == IA)
            count++;
        }
        if (count == 2 && !ligne.contains(mouvement.getDepart()))
          if (!possibilitesMoulinIA.contains(mouvement))
            possibilitesMoulinIA.add(mouvement);
      }
    }
    return possibilitesMoulinIA;
  }
  
  /**
   * on détermine si on peut bloquer un moulin potentiel du joueur
   */
  List deplacePionIA_BlockJoueurMorrisPossibilites(List possibilites) {
    List possibilitesMoulinJoueur = new List();
    for(Mouvement mouvement in possibilites) {
      List cellLignes = getLignesFromCell(mouvement.getArrive());
      
      int joueur1 = 0;
      int joueur2 = 0;
      TableCellElement c1 = null;
      TableCellElement c2 = null;
      
      //On compte le nombre d'élements du joueur dans chaque ligne
      for(TableCellElement cell in cellLignes[0]) {
        if (getCellClass(cell) == JOUEUR) {
          joueur1++;
          c1 = cell;
        }
      }
      
      for(TableCellElement cell in cellLignes[1]) {
        if (getCellClass(cell) == JOUEUR) {
          joueur2++;
          c2 = cell;
        }
      }
      
      //Si une ligne contient deux pièces du joueur et l'autre une, on détermine si la pièce isolée est voisine de l'élément commun
      if (joueur1 == 2 && joueur2 == 1) {
        if (areNeighbor(cellLignes[1], mouvement.getArrive(), c2))
          if(!possibilitesMoulinJoueur.contains(possibilitesMoulinJoueur))
            possibilitesMoulinJoueur.add(mouvement);
      }
      
      if (joueur1 == 1 && joueur2 == 2) {
        if (areNeighbor(cellLignes[0], mouvement.getArrive(), c1))
          if(!possibilitesMoulinJoueur.contains(possibilitesMoulinJoueur))
            possibilitesMoulinJoueur.add(mouvement);
      }
    }
    
    return possibilitesMoulinJoueur;
  }
  
  /**
   * on détermine si l'on peut défaire un moulin en vue de le refaire, ceci en étant sur de ne pas se faire bloquer ou détruire
   */
  List deplacePionIA_BreakMorrisPossibilites(List possibilites) {
    List possibilitesBreakMoulinIA = new List();
    for(Mouvement mouvement in possibilites) {
      List cellLignes = getLignesFromCell(mouvement.getDepart());
      bool morris = false;
      for(List ligne in cellLignes) {
        if (testMorris(ligne))
          morris = true;
      }
      
      if(morris) {
        List ligne = getLigneFromCells(mouvement.getDepart(), mouvement.getArrive());
        TableCellElement cellJoueur = null;
        for(TableCellElement cell in ligne) {
          if (getCellClass(cell) == JOUEUR)
            cellJoueur = cell;
        }
        if (cellJoueur == null || !areNeighbor(ligne, mouvement.getDepart(), cellJoueur))
          if (!possibilitesBreakMoulinIA.contains(mouvement))
            possibilitesBreakMoulinIA.add(mouvement);
      }
    }
    return possibilitesBreakMoulinIA;
  }

  /**
   * on détermine si un pion bloque un moulin potentiel, auquel cas on ne le bouge pas
   */
  List deplacePionIA_BlockJoueurMorris(List possibilites) {
    List bloqueDejaMoulin = new List();
    for (Mouvement mouvement in possibilites) {
      List cellLignes = getLignesFromCell(mouvement.getDepart());
      
      int ligne1Joueur = 0;
      TableCellElement c1 = null;
      for(TableCellElement cell in cellLignes[0]) {
        if (getCellClass(cell) == JOUEUR) {
          ligne1Joueur++;
          c1 = cell;
        }
      }
      
      int ligne2Joueur = 0;
      TableCellElement c2 = null;
      for(TableCellElement cell in cellLignes[1]) {
        if (getCellClass(cell) == JOUEUR) {
          ligne2Joueur++;
          c2 = cell;
        }
      }
      
      if (ligne1Joueur == 2 && ligne2Joueur == 1) {
        if (areNeighbor(cellLignes[1], mouvement.getDepart(), c2))
          if(!bloqueDejaMoulin.contains(mouvement))
            bloqueDejaMoulin.add(mouvement);
      }
      
      if (ligne1Joueur == 1 && ligne2Joueur == 2) {
        if (areNeighbor(cellLignes[0], mouvement.getDepart(), c1))
          if(!bloqueDejaMoulin.contains(mouvement))
            bloqueDejaMoulin.add(mouvement);
      }
    }
    return bloqueDejaMoulin;
  }
  
  /**
   * on cherche à bloquer les mouvements du joueur
   */
  List deplacePionIA_BlockJoueurMovPossibilites(List possibilites, List possibilitesJoueur) {
    List bloqueJoueur = new List();
    for(Mouvement mouvJoueur in possibilitesJoueur) {
      for(Mouvement mouvIA in possibilites) {
        if (mouvJoueur.getArrive() == mouvIA.getArrive()) {
          if (!bloqueJoueur.contains(mouvIA))
            bloqueJoueur.add(mouvIA);
        }
      }
    }
    return bloqueJoueur;
  }
  
  /**
   * on détermine quels mouvements il ne vaut mieux pas exécuter car si le joueur bouge la mauvaise pièce alors son moulins peut être bloqué
   */
  List deplacePionIA_WaitBlockMorrisPossibilites(List possibilites) {
    List possibilitesBloqueMoulinsJoueur = new List();
    for(Mouvement mouvement in possibilites) {
      var ligneUnused = getLigneFromCells(mouvement.getDepart(), mouvement.getArrive());
      List ligne1;
      for(List l in getLignesFromCell(mouvement.getDepart())) {
        if (l != ligneUnused)
          ligne1 = l;
      }
      
      for (TableCellElement cell in ligne1) {
        if (cell != mouvement.getDepart() && areNeighbor(ligne1, cell, mouvement.getDepart())) {
          if (getCellClass(cell) == JOUEUR) {
            var lignesCell = getLignesFromCell(cell);
            for (List ligne2 in lignesCell) {
              if (ligne2 != ligne1) {
                if (testMorris(ligne2) && !possibilitesBloqueMoulinsJoueur.contains(mouvement))
                  possibilitesBloqueMoulinsJoueur.add(mouvement);
              }
            }
          }
        }
      }
    }
    
    return possibilitesBloqueMoulinsJoueur;
  }
  
  /**
   * on détermine si on peut bloqué la destruction d'un moulin du joueur pour l'empêcher de le reconstruire
   */
  List deplacePionIA_BlockBreakMorrisPossibilites(List possibilites) {
    List possibilitesBlockBreakMorris = new List();
    for(List ligne in lignes) {
      if (testMorris(ligne) && getCellClass(ligne[0]) == JOUEUR) {
        int counter = 0;
        TableCellElement arrive;
        for(TableCellElement cell in ligne) {
          int i = deplacePionIAJoueurFly_CountNombreMouvementsPossiblePourArrive(possibilites, cell);
          counter = counter + i;
          if (i > 0)
            arrive = cell;
        }
        
        if (counter == 1 && !possibilitesBlockBreakMorris.contains(arrive))
          possibilitesBlockBreakMorris.add(arrive);
      }
    }
    
    return possibilitesBlockBreakMorris;
  }
  
  
  
  
  
  /**
   * Gère la startégie de l'IA pour retirer un pion du joueur pendant la phase de déplacement
   */
  void retirePionIAPhaseDeplacement() {
    List possibilites = new List();
    List possibilitesBreakMorris = new List();
    List possibilitesJoueurBlocMorris = new List();

    //Première partie : on référence une fois tous les pions du joueur qui ne sont pas dans des moulins
    possibilites = retirePionIA_ReferenceJoueur();
    
    //Deuxième partie : on détermine si le joueur peut créer un moulin en un déplacement (deux sur une ligne, et le troisième voisin de l'élément commun)
    possibilitesBreakMorris = retirePionIAPhaseDeplacement_JoueurMorrisPossibilites(possibilites);
    
    //Troisième partie : on détermine si un pion du joueur bloque un moulin de l'IA
    possibilitesJoueurBlocMorris = retirePionIAPhaseDeplacement_JoueurBlockMorris(possibilites);
    
    //Dernière partie, on détermine quel pion enlever, priorité : possibilitesBreakMorris
    List possibilitesRetenues = new List();
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesBreakMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurBlocMorris);
    
    if (possibilitesRetenues.length > 0) {
      List cells = getMostRefferenced(possibilitesRetenues);
      TableCellElement cell = getRandomElement(cells);
      retirePionAdverse(cell);
    } else if(possibilites.length > 0) {
      TableCellElement cell = getRandomElement(possibilites); 
      retirePionAdverse(cell);
    } else {
      setMorris(false);
      tourSuivant();
    }
  }
  
  /**
   * on détermine si le joueur peut créer un moulin en un déplacement (deux sur une ligne, et le troisième voisin de l'élément commun)
   */
  List retirePionIAPhaseDeplacement_JoueurMorrisPossibilites(List possibilites) {
    List possibilitesBreakMorris = new List();
    for (List ligne1 in lignes) {
      for (List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null && getCellClass(commun) == VIDE) {
          int joueur1 = 0;
          int joueur2 = 0;
          TableCellElement c1 = null;
          TableCellElement c2 = null;
          
          //On compte le nombre d'élements du joueur dans chaque ligne
          for(TableCellElement cell in ligne1) {
            if (getCellClass(cell) == JOUEUR) {
              joueur1++;
              c1 = cell;
            }
          }
          
          for(TableCellElement cell in ligne2) {
            if (getCellClass(cell) == JOUEUR) {
              joueur2++;
              c2 = cell;
            }
          }
          
          //Si une ligne contient deux pièces du joueur et l'autre une, on détermine si la pièce isolée est voisine de l'élément commun
          if (joueur1 == 2 && joueur2 >= 1 && areNeighbor(ligne2, commun, c2) || 
            joueur1 >= 1 && joueur2 == 2 && areNeighbor(ligne1, commun, c1)) {
            for (TableCellElement cell in ligne1) {
             if (possibilites.contains(cell))
               possibilitesBreakMorris.add(cell);
            }
            for (TableCellElement cell in ligne2) {
              if (possibilites.contains(cell))
                possibilitesBreakMorris.add(cell);
            }
          } 
        }
      }
    }
    return possibilitesBreakMorris;
  }
  
  /**
   * on détermine si un pion du joueur bloque un moulin de l'IA
   */
  List retirePionIAPhaseDeplacement_JoueurBlockMorris(List possibilites) {
    List possibilitesJoueurBlocMorris = new List();
    for(TableCellElement cell in possibilites) {
      List cellLignes = getLignesFromCell(cell);  
      
      var cell1;
      int ligne1 = 0;
      for(TableCellElement c in cellLignes[0]) {
        if (getCellClass(c) == IA) {
          ligne1++;
          cell1 = c;
        }
      }
      
      var cell2;
      int ligne2 = 0;
      for(TableCellElement c in cellLignes[1]) {
        if (getCellClass(c) == IA) {
          ligne2++;
          cell2 = c;
        }
      }
      
      if (ligne1 == 2 && ligne2 > 0) {
        if (areNeighbor(cellLignes[1], cell, cell2))
          if (!possibilitesJoueurBlocMorris.contains(cell))
            possibilitesJoueurBlocMorris.add(cell);
      }
      
      if (ligne1 > 0 && ligne2 == 2) {
        if (areNeighbor(cellLignes[0], cell, cell1))
          if (!possibilitesJoueurBlocMorris.contains(cell))
            possibilitesJoueurBlocMorris.add(cell);
      }
    }
    return possibilitesJoueurBlocMorris;
  }
  
  
  
  
  
  /**
   * Gère la stratégie de déplacement des pions de l'IA avec le joueur en fly
   */
  void deplacePionIAJoueurFly() {
    List possibilites = new List();
    List possibilitesMoulinIA = new List();
    List possibilitesMoulinJoueur = new List();
    List possibilitesBreakMorris = new List();
    List possibilitesBlockJoueurAngle = new List();
    bool playerCanMakeMorris = false;
    bool playerCanMakeAngle = false;
    
    //Première partie : on détermine tous les pions pouvant être déplacés par l'IA
    for(List ligne in lignes) {
      for (TableCellElement cell in ligne) {
        if (getCellClass(cell) == IA) {
          for (TableCellElement c in getFreeNeighbor(cell)) {
           int count = 0;
           for (Mouvement mouvement in possibilites) {
             if (mouvement.getDepart() == cell && mouvement.getArrive() == c)
               count++;
           }
           if (count == 0)
             possibilites.add(new Mouvement(cell, c));
          }
        }
      }
    }
    
    //Deuxième partie : On détermine si l'IA est en mesure de créer un moulin
    possibilitesMoulinIA = deplacePionIA_MorrisPossibilites(possibilites);
    
    //Troisième partie : On détermine si le joueur est en mesure de créer un moulin
    playerCanMakeMorris = deplacePionIAJoueurFly_JoueurCanMakeMorris();
    
    //Quatrième partie : on détermine si on peut bloquer un moulin potentiel du joueur
    if (playerCanMakeMorris) {
      possibilitesMoulinJoueur = deplacePionIA_BlockJoueurMorrisPossibilites(possibilites);
    }
    
    //Cinquième partie : On détermine si l'on peut défaire un moulin en vue de le refaire
    possibilitesBreakMorris = deplacePionIAJoueurFly_BreakMorrisPossibilites(possibilites);
    
    //Sixième partie : On détermine si le joueur peut créer une situation d'angle
    playerCanMakeAngle = deplacePionIAJoueurFly_JoueurCanMakeAngle();
    
    //Septième partie : On détermine si l'IA peut bloquer la création de l'angle
    if (playerCanMakeAngle) {
      possibilitesBlockJoueurAngle = deplacePionIAJoueurFly_BlockPlayerAnglePossibilites(possibilites);
    }
    
    //Dernière partie : choix du mouvement, priotités : possibilitesMoulinIA > possibilitesMoulinJoueur > possibilitesBlockJoueurAngle
    List possibilitesRetenues = new List();    
    
    possibilitesBreakMorris = removeElementsRefferenced(possibilitesBreakMorris, possibilitesMoulinIA);
    
    if (!deplacePionIAJoueurFly_JoueurIsMorris())
      possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMoulinIA);
    //Cas où l'on peut créer deux morris différent et que le joueur est en morris, on attend le tour suivant pour en créer un
    //sinon on protège le morris potentiel en le fermant
    else if (deplacePionIAJoueurFly_JoueurIsMorris() && deplacePionIAJoueurFly_CountNombreDestinations(possibilitesMoulinIA) <= 1)
      possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMoulinIA);
      
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMoulinJoueur);
    if (!playerCanMakeMorris)
      possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesBreakMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesBlockJoueurAngle);

    if (playerCanMakeMorris)
      possibilitesRetenues = removeElementsRefferenced(possibilitesRetenues, possibilitesBreakMorris);
    
    List possibilitesFinales = getMostRefferenced(possibilitesRetenues);
    
    setMouvementIA(getRandomElement(possibilitesFinales));
    if (possibilites.length > 0 && possibilitesFinales.length == 0 && getMouvementIA() == null)
      setMouvementIA(getRandomElement(possibilites));
    
    if (possibilites.length == 0) {
      phaseFinDePartie(true);
    } else {
      timer = new Timer(new Duration(seconds: 1), deplacePionIADelay);
    }
  }
  
  /**
   * Retourne true si le joueur est en mesure de créer un moulin
   */
  bool deplacePionIAJoueurFly_JoueurCanMakeMorris() {
    bool result = false;
    for(List ligne in lignes) {
      int joueurCount = 0;
      int videCount = 0;
      for(TableCellElement cell in ligne) {
       if (getCellClass(cell) == JOUEUR)
         joueurCount++;
       if (getCellClass(cell) == VIDE)
         videCount++;
      }
      
      if (joueurCount == 2 && videCount == 1)
        result = true;
    }
    return result;
  }
  
  /**
   * Gère la destruction d'un moulin en vu de le refaire
   */
  List deplacePionIAJoueurFly_BreakMorrisPossibilites(List possibilites) {
    List possibilitesBreakMoulinIA = new List();
    for(Mouvement mouvement in possibilites) {
      List cellLignes = getLignesFromCell(mouvement.getDepart());
      bool morris = false;
      for(List ligne in cellLignes) {
        if (testMorris(ligne))
          morris = true;
      }
      
      if(morris) {
        List ligne = getLigneFromCells(mouvement.getDepart(), mouvement.getArrive());
        int IACount = 0;
        for(TableCellElement cell in ligne) {
          if (getCellClass(cell) == IA)
            IACount++;
        }

        if (IACount == 1) {
          //cas ou le pion à déplacer est seul IA sur la ligne, on ne recréé pas un nouveau moulin
          if (!possibilitesBreakMoulinIA.contains(mouvement))
            possibilitesBreakMoulinIA.add(mouvement);
        } else if (deplacePionIAJoueurFly_CountNombreMouvementsPossiblePourArrive(possibilites, mouvement.getArrive()) == 2) {
          //cas où l'on a un autre pion IA sur la ligne, on ne bloque (counter==3) ou ne recréé (counter==4) de moulin
          if (!possibilitesBreakMoulinIA.contains(mouvement))
            possibilitesBreakMoulinIA.add(mouvement);
        }
      }
    }
    return possibilitesBreakMoulinIA;
  }
  
  /**
   * Retourne true si le joueur est en moulin (intéressant si l'IA a plusieurs possibilitées de moulins)
   */
  bool deplacePionIAJoueurFly_JoueurIsMorris() {
    for(List ligne in lignes) {
      if (testMorris(ligne)) {
        for(TableCellElement cell in ligne) {
          if (getCellClass(cell) == JOUEUR)
            return true;
          break;
        }
      }
    }
    return false;
  }
  
  /**
   * Retourne true si le le joueur est en mesure de créer un angle (commun VIDE, un JOUEUR par ligne et aucun IA)
   */
  bool deplacePionIAJoueurFly_JoueurCanMakeAngle() {
    for (List ligne1 in lignes) {
      for (List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null && getCellClass(commun) == VIDE) {
          int playerLigne1 = 0;
          int videLigne1 = 0;
          int playerLigne2 = 0;
          int videLigne2 = 0;
          
          for(TableCellElement cell in ligne1) {
            if (getCellClass(cell) == VIDE)
              videLigne1++;
            if (getCellClass(cell) == JOUEUR)
              playerLigne1++;
          }
          
          for(TableCellElement cell in ligne2) {
            if (getCellClass(cell) == VIDE)
              videLigne2++;
            if (getCellClass(cell) == JOUEUR)
              playerLigne2++;
          }
          
          if (playerLigne1 == 1 && playerLigne2 == 1 && videLigne1 == 2 && videLigne2 == 2)
            return true;
        }
      }
    }
    return false;
  }
  
  /**
   * On détermine si l'IA peut bloquer la création de l'angle
   */
  List deplacePionIAJoueurFly_BlockPlayerAnglePossibilites(List mouvements) {
    List possibilitesMoulinJoueur = new List();
    List vides = new List();
    for (List ligne1 in lignes) {
      for (List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if(commun != null && getCellClass(commun) == VIDE && vides.length == 0) {
          int playerLigne1 = 0;
          for (TableCellElement cell in ligne1) {
            if (getCellClass(cell) == VIDE && !vides.contains(cell))
              vides.add(cell);
            if (getCellClass(cell) == JOUEUR)
              playerLigne1++;
          }
          int playerLigne2 = 0;
          for (TableCellElement cell in ligne2) {
            if (getCellClass(cell) == VIDE && !vides.contains(cell))
              vides.add(cell);
            if (getCellClass(cell) == JOUEUR)
              playerLigne2++;
          }
          
          if (!(playerLigne1 == 1 && playerLigne2 == 1 && vides.length == 3))
            vides.clear();
        }
      }
    }
    
    for (Mouvement mouvement in mouvements) {
      if (vides.contains(mouvement.getArrive())) {
        if (!possibilitesMoulinJoueur.contains(mouvement))
          possibilitesMoulinJoueur.add(mouvement);
      }
    }
    
    return possibilitesMoulinJoueur;
  }
  
  /**
   * Retourne le nombre de destinations possibles
   */
  int deplacePionIAJoueurFly_CountNombreDestinations(List mouvements) {
    List destinations = new List();
    for(Mouvement mouvement in mouvements) {
      if (!destinations.contains(mouvement.getArrive()))
        destinations.add(mouvement.getArrive());
    }
    return destinations.length;
  }
  
  /**
   * Retourne le nombre de mouvements capables d'atteindre la cellule spécifiée
   */
  int deplacePionIAJoueurFly_CountNombreMouvementsPossiblePourArrive(List mouvements, TableCellElement cell) {
    int count = 0;
    for(Mouvement mouvement in mouvements) {
      if (mouvement.getArrive() == cell)
        count++;
    }
    return count;
  }
  
  
  
  
  
  /**
   * Gère la stratégie de déplacement fly de l'IA avec le joueur en déplacement normal
   */
  void flyPionIA() {
    List elementsIA = new List();
    List mouvementsJoueur = new List();
    List mouvementsIA = new List();
    List iaBlocMorris = new List();
    List possibilitesMorris = new List();
    List possibilitesLigne = new List();
    List possibilitesAngle = new List();
    List possibilitesPrepareAngle = new List();
    List possibilitesMorrisPlayer = new List();
    bool playerCanMakeMorris = false;
    bool iaIsMorris = false;
    
    //Première partie : on référence toutes les cellules de l'IA
    elementsIA = flyPionIA_ReferenceAllCellByType(IA);
    
    //Deuxième partie : on référence tous les mouvements réalisables par le joueur et l'IA
    mouvementsJoueur = deplacePionIA_ReferenceIAMouvements(JOUEUR);
    mouvementsIA =  flyPionIA_ReferenceAllMouvmentByType(IA);
    
    //Troisème partie : on référence tous les pions qui bloques un moulin du joueur
    iaBlocMorris = flyPionIA_CellBlockPlayerMorris(mouvementsIA);
    
    //Quatrième partie : on détermine si l'on peut créer un moulin
    possibilitesMorris = flyPionIAetJoueurFly_MorrisPossibilites(IA, mouvementsIA);
    
    //Cinquième partie : on détermine si l'on peut créer une ligne
    possibilitesLigne = flyPionIA_LignePossibilites(mouvementsIA);
    
    //Sixième partie : on détermine si l'on peut créer un angle
    possibilitesAngle = flyPionIAetJoueurFly_AnglePossibilites(IA, mouvementsIA);
    
    //Septième partie : On détermine quels mouvements peut faire l'IA pour bloquer un moulin du joueur
    possibilitesMorrisPlayer = flyPionIA_PlayerMorrisPossibilites(mouvementsJoueur, mouvementsIA);
    
    //Huitième partie : on détermine si l'on peut préparer un angle
    possibilitesPrepareAngle = flyPionIAetJoueurFly_PrepareAngle(mouvementsIA);
    
    //Dernière partie : on détermine quel emplacement occuper et par quel pion
    List possibilitesRetenues = new List();
    iaBlocMorris = removeElementsRefferenced(iaBlocMorris, possibilitesMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMorrisPlayer);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesAngle);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesPrepareAngle);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesLigne);
    possibilitesRetenues = removeElementsRefferenced(possibilitesRetenues, iaBlocMorris);
    
    List possibilitesFinales = getMostRefferenced(possibilitesRetenues);
    setMouvementIA(getRandomElement(possibilitesFinales));
    if (mouvementsIA.length > 0 && possibilitesFinales.length == 0 && getMouvementIA() == null)
      setMouvementIA(getRandomElement(mouvementsIA));
    
    timer = new Timer(new Duration(seconds: 1), deplacePionIADelay);
  }
  
  /**
   * Référence une fois toutes les cellules vides
   */
  List flyPionIA_ReferenceAllCellByType(String type) {
    List elements = new List();
    
    for (List ligne in lignes) {
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == type && !elements.contains(cell))
          elements.add(cell);
      }
    }
    return elements;
  }
  
  /**
   * Référence tous les mouvements possibles
   */
  List flyPionIA_ReferenceAllMouvmentByType(String type) {
    List mouvementsPossibles = new List();
    if (type != VIDE) {
      for (List ligne1 in lignes) {
        for(TableCellElement cell1 in ligne1) {
          if (getCellClass(cell1) == type) {
            for (List ligne2 in lignes) {
              for(TableCellElement cell2 in ligne2) {
                if (getCellClass(cell2) == VIDE)
                  mouvementsPossibles.add(new Mouvement(cell1, cell2));
              }
            }
          }
        }
      }
    }
    return mouvementsPossibles;
  }
  
  /**
   * Référence tous les pions qui bloques un moulin du joueur
   */
  List flyPionIA_CellBlockPlayerMorris(List mouvementsIA) {
    List mouvements = new List();
    for(int id = 1; id < 24; id++) {
      TableCellElement cell = getCell(id);
      if (getCellClass(cell) == IA) {
        List lignesCell = getLignesFromCell(cell);
        
        int joueurLigne1 = 0;
        var cellLigne1;
        int joueurLigne2 = 0;
        var cellLigne2;
        
        
        for(TableCellElement c in lignesCell[0]) {
          if (getCellClass(c) == JOUEUR) {
            joueurLigne1++;
            cellLigne1 = c;
          }
        }
        for(TableCellElement c in lignesCell[1]) {
          if (getCellClass(c) == JOUEUR) {
            joueurLigne2++;
            cellLigne2 = c;
          }
        }
        
        if (joueurLigne1 == 2 && joueurLigne2 == 2) {
          for (Mouvement mouvement in mouvementsIA) {
            if (mouvement.getDepart() == cell && !mouvements.contains(mouvement))
              mouvements.add(mouvement);
          }
        } else if (joueurLigne1 == 2 && joueurLigne2 == 1 && areNeighbor(lignesCell[1], cell, cellLigne2)) {
          for (Mouvement mouvement in mouvementsIA) {
            if (mouvement.getDepart() == cell && !mouvements.contains(mouvement))
              mouvements.add(mouvement);
          }
        } else if (joueurLigne1 == 1 && joueurLigne2 == 2 && areNeighbor(lignesCell[0], cell, cellLigne1)) {
          for (Mouvement mouvement in mouvementsIA) {
            if (mouvement.getDepart() == cell && !mouvements.contains(mouvement))
              mouvements.add(mouvement);
          }
        }
      }
    }
    
    return mouvements;
  }
  
  /**
   * on détermine si une ligne a un élément de l'IA et aucun du joueur
   */
  List flyPionIA_LignePossibilites(List mouvementsIA) {
    List possibilitesJoueurCreeLigne = new List();
    for(List ligne in lignes) {
      int ia = 0;
      int joueur = 0;
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == JOUEUR)
          joueur++;
        if (getCellClass(cell) == IA)
          ia++;
      }
      if (ia == 1 && joueur == 0) {
        for(Mouvement mouvement in mouvementsIA) {
          if (!ligne.contains(mouvement.getDepart()) && ligne.contains(mouvement.getArrive()) 
              && !possibilitesJoueurCreeLigne.contains(mouvement))
            possibilitesJoueurCreeLigne.add(mouvement);
        }
      }
    }
    return possibilitesJoueurCreeLigne;
  }
  
  /**
   * Retourne true si le joueur est en mesure de créer un moulin
   */
  bool flyPionIA_JoueurCanMakeMorris(List mouvementsJoueur) {
    for (Mouvement mouvement in mouvementsJoueur) {
      List lignesCell = getLignesFromCell(mouvement.getArrive());
      for(List ligne in lignesCell) {
        if (ligne != getLigneFromCells(mouvement.getDepart(), mouvement.getArrive())) {
          int joueurLigne = 0;
          for(TableCellElement cell in ligne) {
            if (getCellClass(cell) == JOUEUR) {
              joueurLigne++;
            }
          }
          
          if (joueurLigne == 2)
            return true;
        }
      }
    }
    return false;
  }
  
  /**
   * Retourne true si l'IA a un moulin
   */
  bool flyPionIA_IAIsMorris() {
    for (List ligne in lignes) {
      if (testMorris(ligne)) {
        if (getCellClass(ligne[0]) == IA)
          return true;
      }
    }
    return false;
  }
  
  /**
   * On détermine quels éléments de l'IA sont dans une ligne
   */
  List flyPionIA_ReferenceIAInLigne() {
    List cells = new List();
    for (int id = 1; id < 24; id++) {
      var cell = getCell(id);
      if (getCellClass(cell) == IA) {
        List lignesCell = getLignesFromCell(cell);
        for (List ligne in lignesCell) {
          for (TableCellElement c in ligne) {
            if (getCellClass(c) == IA && !cells.contains(c))
              cells.add(c);
          }
        }
        if (cells.length < 2)
          cells.clear();
        else {
          cells.add(cell);
          break;
        }
      }
    }
    return cells;
  }
  
  /**
   * On détermine quels mouvements peut faire l'IA pour bloquer un moulin du joueur
   */
  List flyPionIA_PlayerMorrisPossibilites(List mouvementsJoueur, List mouvementsIA) {
    List possibilitesMorrisPlayer = new List();
    for (Mouvement mouvementPlayer in mouvementsJoueur) {
      List lignesCell = getLignesFromCell(mouvementPlayer.getArrive());
      for(List ligne in lignesCell) {
        if (ligne != getLigneFromCells(mouvementPlayer.getDepart(), mouvementPlayer.getArrive())) {
          int joueurLigne = 0;
          for(TableCellElement cell in ligne) {
            if (getCellClass(cell) == JOUEUR) {
              joueurLigne++;
            }
          }
          
          if (joueurLigne == 2) {
            for (Mouvement mouvementIA in mouvementsIA) {
              if (mouvementIA.getArrive() == mouvementPlayer.getArrive() && !possibilitesMorrisPlayer.contains(mouvementIA))
                possibilitesMorrisPlayer.add(mouvementIA);
            }
          }
        }
      }
    }
    return possibilitesMorrisPlayer;
  }
  
  
  
  
  
  /**
   * Gère la supression d'un pion du joueur quand l'IA est en fly
   */
  void retirePionIAFly() {
    List possibilites = new List();
    List possibilitesBreakMorris = new List();
    List possibilitesJoueurBlocMorris = new List();
    List possibilitesAngle = new List();

    //Première partie : on référence une fois tous les pions du joueur qui ne sont pas dans des moulins
    possibilites = retirePionIA_ReferenceJoueur();
    
    //Deuxième partie : on détermine si le joueur peut créer un moulin en un déplacement (deux sur une ligne, et le troisième voisin de l'élément commun)
    possibilitesBreakMorris = retirePionIAPhaseDeplacement_JoueurMorrisPossibilites(possibilites);
    
    //Troisième partie : on détermine si un pion du joueur bloque un moulin de l'IA
    possibilitesJoueurBlocMorris = retirePionIAPhaseDeplacement_JoueurBlockMorris(possibilites);
    
    //Quatrième partie : on détermine si un pion du joueur bloque un angle de l'IA
    possibilitesAngle = retirePionIAFly_PlayerBlockAngle(possibilites);
    
    //Dernière partie, on détermine quel pion enlever, priorité : possibilitesBreakMorris
    List possibilitesRetenues = new List();
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesBreakMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesJoueurBlocMorris);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesAngle);
    
    if (possibilitesRetenues.length > 0) {
      List cells = getMostRefferenced(possibilitesRetenues);
      TableCellElement cell = getRandomElement(cells);
      retirePionAdverse(cell);
    } else if(possibilites.length > 0) {
      TableCellElement cell = getRandomElement(possibilites); 
      retirePionAdverse(cell);
    } else {
      setMorris(false);
      tourSuivant();
    }
  }
  
  /**
   * On détermine si un pion du joueur bloque un angle de l'IA
   */
  List retirePionIAFly_PlayerBlockAngle(List possibilites) {
    List possibilitesAngle = new List();
    for (List ligne1 in lignes) {
      for (List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (getCellClass(commun) != IA) {
          int iaCounter1 = 0;
          int iaCounter2 = 0;
          
          for (TableCellElement cell in ligne1) {
            if (getCellClass(cell) == IA)
              iaCounter1++;
          }
          for (TableCellElement cell in ligne2) {
            if (getCellClass(cell) == IA)
              iaCounter2++;
          }
          
          if (iaCounter1 > 0 && iaCounter2 > 0) {
            for (TableCellElement cell in possibilites) {
              if (ligne1.contains(cell) || ligne2.contains(cell)) {
                if (!possibilitesAngle.contains(cell))
                  possibilitesAngle.add(cell);
              }
            }
          }
        }
      }
    }
    return possibilitesAngle;
  }
  
  
  
  
  
  /**
   * Gère la stratégie de déplacement fly des pions de l'IA avec le joueur en fly
   */
  void flyPionIAEtJoueurFly() {
    List mouvementsIA = new List();
    List elementsIA = new List();
    List elementsPlayer = new List();
    
    List possibilitesMorrisIA = new List();
    List possibilitesMorrisPlayer = new List();
    List possibilitesAngleIA = new List();
    List possibilitesAnglePlayer = new List();
    List possibilitesPrepareAngle = new List();
    
    List iaBlocMorris = new List();
    List iaBlocAngle = new List();
    
    //Première partie : on référence tous les éléments du joueur et de l'IA
    elementsIA = flyPionIA_ReferenceAllCellByType(IA);
    elementsPlayer = flyPionIA_ReferenceAllCellByType(JOUEUR);
    mouvementsIA = flyPionIA_ReferenceAllMouvmentByType(IA);
    
    //Deuxième partie : on référence les possibilitées de moulin pour le joueur et l'ia
    possibilitesMorrisIA = flyPionIAetJoueurFly_MorrisPossibilites(IA, mouvementsIA);
    possibilitesMorrisPlayer = flyPionIAetJoueurFly_MorrisPossibilites(JOUEUR, mouvementsIA);
    
    //Troisème partie : on référence les possibilitées de d'angle pour le joueur et l'ia
    possibilitesAngleIA = flyPionIAetJoueurFly_AnglePossibilites(IA, mouvementsIA);
    possibilitesAnglePlayer = flyPionIAetJoueurFly_AnglePossibilites(JOUEUR, mouvementsIA);
    
    //Quatrième partie : on référence les possibilitées pour préparer une situation de prise d'angle
    possibilitesPrepareAngle = flyPionIAetJoueurFly_PrepareAngle(mouvementsIA);
    
    //Cinquième partie : on référence les pions de l'IA qui bloquent un moulin ou un angle du joueur
    iaBlocMorris = flyPionIAetJoueurFly_BlockMorris(mouvementsIA);
    iaBlocAngle = flyPionIAetJoueurFly_BlockAngle(mouvementsIA);
    
    //Dernière partie : on détermine quel emplacement occuper et avec quel pion
    List possibilitesRetenues = new List();
    iaBlocMorris = removeElementsRefferenced(iaBlocMorris, possibilitesMorrisIA);
    iaBlocAngle = removeElementsRefferenced(iaBlocAngle, possibilitesMorrisIA);
    iaBlocAngle = removeElementsRefferenced(iaBlocAngle, possibilitesAngleIA);
    
    if (!deplacePionIAJoueurFly_JoueurIsMorris())
      possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMorrisIA);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesMorrisPlayer);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesAngleIA);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesAnglePlayer);
    possibilitesRetenues = addElementsRefferenced(possibilitesRetenues, possibilitesPrepareAngle);
    possibilitesRetenues = removeElementsRefferenced(possibilitesRetenues, iaBlocMorris);
    possibilitesRetenues = removeElementsRefferenced(possibilitesRetenues, iaBlocAngle);
    
    List possibilitesFinales = getMostRefferenced(possibilitesRetenues);
    setMouvementIA(getRandomElement(possibilitesFinales));
    if (mouvementsIA.length > 0 && possibilitesFinales.length == 0 && getMouvementIA() == null)
      setMouvementIA(getRandomElement(mouvementsIA));
    
    timer = new Timer(new Duration(seconds: 1), deplacePionIADelay);
  }
  
  /**
   * Retourne la liste des déplacements possibles pour prendre un moulin
   */
  List flyPionIAetJoueurFly_MorrisPossibilites(String type, List mouvementsIA) {
    List mouvements = new List();
    for(List ligne in lignes) {
      int counter = 0;
      int counterVide = 0;
      for (TableCellElement cell in ligne) {
        if (getCellClass(cell) == type)
          counter++;
        if (getCellClass(cell) == VIDE)
          counterVide++;
      }
      
      if(counter == 2 && counterVide == 1) {
        for (TableCellElement cell in ligne) {
          if (getCellClass(cell) == VIDE) {
            for (Mouvement mouvement in mouvementsIA) {
              if (!ligne.contains(mouvement.getDepart()) && mouvement.getArrive() == cell)
                if (!mouvements.contains(mouvement))
                  mouvements.add(mouvement);
            }
          }
        }
      }
    }
    return mouvements;
  }
  
  /**
   * Retourne la liste des déplacements possibles pour prendre un angle
   */
  List flyPionIAetJoueurFly_AnglePossibilites(String type, List mouvementsIA) {
    List mouvements = new List();
    
    for(List ligne1 in lignes) {
      for(List ligne2 in lignes) {
        TableCellElement commun = getElementCommun(ligne1, ligne2);
        if (commun != null && getCellClass(commun) == VIDE){
          bool l1IA = ligneAElementExceptCommun(ligne1, commun, type);
          bool l2IA = ligneAElementExceptCommun(ligne2, commun, type);
          if (l1IA && l2IA) {
            for (Mouvement mouvement in mouvementsIA) {
              if (!ligne1.contains(mouvement.getDepart()) && !ligne2.contains(mouvement.getDepart()) && mouvement.getArrive() == commun) {
                if (!mouvements.contains(mouvement))
                  mouvements.add(mouvement);
              }
            }
          }
        }
      }
    }
    
    return mouvements;
  }
  
  /**
   * Retourne une liste d'emplacements qui permettent au tour suivant de gérer un angle
   */
  List flyPionIAetJoueurFly_PrepareAngle(List mouvementsIA) {
    List possibilitesPrepareAngle = new List();
    for (int id = 1; id < 24; id++) {
      TableCellElement commun = getCell(id);
      if (getCellClass(commun) == VIDE) {
        List lignesCell = getLignesFromCell(commun);
        
        int videLigne1 = 0;
        int iaLigne1 = 0;
        for (TableCellElement cell in lignesCell[0]) {
          if (getCellClass(cell) == IA)
            iaLigne1++;
          if (getCellClass(cell) == VIDE)
            videLigne1++;
        }
        
        int videLigne2 = 0;
        int iaLigne2 = 0;
        for (TableCellElement cell in lignesCell[1]) {
          if (getCellClass(cell) == IA)
            iaLigne2++;
          if (getCellClass(cell) == VIDE)
            videLigne2++;
        }
        List ligne1 = lignesCell[0];
        List ligne2 = lignesCell[1];
        
        if (videLigne1 == 3 && videLigne2 == 2 && iaLigne2 == 1 || videLigne1 == 2 && iaLigne1 == 1 && videLigne2 == 3) {
          for (Mouvement mouvement in mouvementsIA) {
            if(mouvement.getArrive() != commun && (ligne1.contains(mouvement.getArrive()) || ligne2.contains(mouvement.getArrive()) &&
                !ligne1.contains(mouvement.getDepart()) && !ligne2.contains(mouvement.getDepart()))) {
              if (!possibilitesPrepareAngle.contains(mouvement))
                possibilitesPrepareAngle.add(mouvement);
            }
          }
        }
      }
    }
    return possibilitesPrepareAngle;
  }
  
  /**
   * Retourne une liste des pions de l'IA qui bloquent un moulin du joueur
   */
  List flyPionIAetJoueurFly_BlockMorris(List mouvementsIA) {
    List blocPlayerMorris = new List();
    for (List ligne in lignes) {
      int iaCounter = 0;
      int playerCounter = 0;
      for (TableCellElement cell in ligne) {
        if (getCellClass(cell) == JOUEUR)
          playerCounter++;
        if (getCellClass(cell) == IA) 
          iaCounter++;
      }
      
      if (playerCounter == 2 && iaCounter == 1) {
        for (Mouvement mouvement in mouvementsIA) {
          if (ligne.contains(mouvement.getDepart()) && !blocPlayerMorris.contains(mouvement)) {
            blocPlayerMorris.add(mouvement);
          }
        }
      }
    }
    return blocPlayerMorris;
  }
  
  /**
   * Retourne une liste des pions de l'IA qui bloquent un angle du joueur
   */
  List flyPionIAetJoueurFly_BlockAngle(List mouvementsIA) {
    List blocPlayerAngle = new List();
    for (int id = 1; id < 24; id++) {
      TableCellElement commun = getCell(id);
      if (getCellClass(commun) == IA) {
        List lignesCell = getLignesFromCell(commun);
        int playerLigne1 = 0;
        int playerLigne2 = 0;
        
        for (TableCellElement cell in lignesCell[0]) {
          if (getCellClass(cell) == JOUEUR)
            playerLigne1++;
        }
        
        for (TableCellElement cell in lignesCell[1]) {
          if (getCellClass(cell) == JOUEUR)
            playerLigne2++;
        }
        
        if (playerLigne1 > 0 && playerLigne2 > 0) {
          for (Mouvement mouvement in mouvementsIA) {
            if (mouvement.getDepart() == commun && !blocPlayerAngle.contains(mouvement))
              blocPlayerAngle.add(mouvement);
          }
        }
      }
    }
    return blocPlayerAngle;
  }
  
  
  
  
  
  /**
   * Méthode appelé pour effectuer le déplacement de l'IA
   */
  void deplacePionIADelay() {    
    if (getMouvementIA() != null) {
      if (nbrPiecesIA > 3)
        deplacePion(getMouvementIA().getArrive());
      else
        flyPion(getMouvementIA().getArrive());
    }
      
    setMouvementIA(null);
    
    if (getMorris()) {
      if (nbrPiecesJoueur > 3)
        timer = new Timer(new Duration(seconds: 1), retirePionIAPhaseDeplacement);
      else
        timer = new Timer(new Duration(seconds: 1), retirePionJoueurFly);
    }
      
  }
  
  /**
   * Gère la supression d'un pion du joueur quand celui-ci est en fly (suppression du premier élément trouvé si il n'est pas ne moulin)
   */
  void retirePionJoueurFly() {
    bool morris = false;
    var cellMorris;
    for(List ligne in lignes) {
      for (TableCellElement cell in ligne) {
        if (getCellClass(cell) == JOUEUR) {
          if (testMorris(ligne))
            morris = true;
          cellMorris = cell;
        }  
      }
      if(morris)
        break;
    }
    
    if (!morris)
      retirePionAdverse(cellMorris);
  }
  
  /**
   * on référence une fois tous les pions du joueur qui ne sont pas dans des moulins
   */
  List retirePionIA_ReferenceJoueur() {
    List possibilites = new List();
    for(List ligne in lignes) {
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == JOUEUR && !possibilites.contains(cell))
          possibilites.add(cell);
      }
    }
    for(List ligne in lignes) {
      if (testMorris(ligne)) {
        for(TableCellElement cell in ligne) {
          if (possibilites.contains(cell))
            possibilites.remove(cell);
        }
      }
    }
    return possibilites;
  }
  
  
  
  
  /**
   * retourne true si le joueur est en mesure de créer un angle
   * (aucune pièce appartenant à l'IA et au moins une pièce du joueur sur chaque ligne)
   */
  bool anglePossibleJoueur(List ligne1, List ligne2, TableCellElement commun) {
    int l1IA = 0;
    int l1Joueur = 0;
    int l2IA = 0;
    int l2Joueur = 0;
    
    for(TableCellElement cell in ligne1) {
      if (cell != commun) {
        if (getCellClass(cell) == JOUEUR)
          l1Joueur++;
        if (getCellClass(cell) == IA)
          l1IA++;
      }
    }
    
    for(TableCellElement cell in ligne2) {
      if (cell != commun) {
        if (getCellClass(cell) == JOUEUR)
          l2Joueur++;
        if (getCellClass(cell) == IA)
          l2IA++;
      }
    }
    
    return (l1IA == 0 && l1Joueur > 0 && l2IA == 0 && l2Joueur >0);
  }
  
  /**
   * Retourne true si le joueur possède 2 éléments dans la ligne et que le troisième est vide
   */
  bool moulinPossibleJoueur(List ligne) {
    int vide = 0;
    int joueur = 0;
    
    //On traite chaque cellule de la ligne
    for (TableCellElement cell in ligne) {
      if (getCellClass(cell) == JOUEUR)
        joueur++;
      else if (getCellClass(cell) == VIDE)
        vide++;
    }
    
    return (joueur == 2 && vide == 1);
  }
  
  /**
   * retourne true si la ligne est vide
   */
  bool ligneVide(List ligne) {
    bool vide = true;
    for(TableCellElement cell in ligne) {
      if (getCellClass(cell) != VIDE)
        vide = false;
    }
    return vide;
  }
  
  /**
   * retourne true si la ligne contient au moins un élément du type spécifié et qui n'est pas sur l'intersection
   */
  bool ligneAElementExceptCommun(List ligne, TableCellElement commun, String type) {
    bool result = false;
    for(TableCellElement cell in ligne) {
      if (cell != commun && getCellClass(cell) == type)
        result = true;
      if (cell != commun && getCellClass(cell) != type && getCellClass(cell) != VIDE)
        return false;
    }
    return result;
  }
  
  /**
   * Retourne la cellule commune aux deux lignes, sinon retourne null
   */
  TableCellElement getElementCommun(List ligne1, List ligne2) {
    TableCellElement result = null;
    if (ligne1 != ligne2) { 
      for(TableCellElement cell in ligne1) {
        if (ligne2.contains(cell))
          result = cell;
      }
    }
    return result;
  }
  
  /**
   * retourne le nombre d'instance de l'élément dans la ligne
   */
  int numberOfInstance(List list, Object o) {
    int count = 0;
    for(Object c in list) {
      if (o == c)
        count++;
    }
    return count;
  }
  
  /**
   * Retourne toutes les lignes contenant la cellule
   */
  List getLignesFromCell(TableCellElement cell) {
    List l = new List();
    for(List ligne in lignes) {
      if (ligne.contains(cell))
        l.add(ligne);
    }
    return l;
  }
  
  /**
   * Retourne la ligne qui contient les deux cellules, sinon retourne null;
   */
  List getLigneFromCells(TableCellElement cell1, TableCellElement cell2) {
    for (List ligne in lignes) {
      if (ligne.contains(cell1) && ligne.contains(cell2))
        return ligne;
    }
    return null;
  }
  
  /**
   * return true si tous les éléments de la ligne sont du même type et différent de la cellule vide
   */
  bool testMorris(List ligne) {
    TableCellElement cell1 = ligne.first;
    if (getCellClass(cell1) != VIDE) {
      int count = 0;
      for(TableCellElement cell in ligne) {
        if (getCellClass(cell) == getCellClass(cell1))
          count++;
      }
      
      return (count == 3);
    }
    return false;
  }
  
  /**
   * Retourne true si il existe au moins un pion du type spécifié qui n'est pas dans un moulins
   */
  bool isAElementOutOfMorris(String searchType) {
    for(List ligne in lignes) {
      //On test si il n'y a pas de moulin, il peut cependant avoir une ligne avec un élément commun qui en possède un
      if (!testMorris(ligne)) {
        for(TableCellElement cell in ligne) {
          if (getCellClass(cell) == searchType) {
            //Chaque cellule appartient à deux lignes, on test alors si au moins l'une des deux a un moulin
            List lignesCell = getLignesFromCell(cell);
            bool morris = false;
            for (List l in lignesCell) {
              if (testMorris(l))
                morris = true;
            }
            if (!morris)
              return true;
          }
        }
      }
    }
    return false;
  }
  
  /**
   * Retourne la ligne contenant les deux cellules et que celles-ci sont différentes si elle existe
   */
  List onSameLine(TableCellElement cell1, TableCellElement cell2) {
    if (cell1 != cell2) {
      for(List ligne in lignes) {
        if (ligne.contains(cell1) && ligne.contains(cell2))
          return ligne;
      }
    }
    return null;
  }
  
  /**
   * Retourne true si les deux cellules sont voisines (pas une à chaque extrêmité de la ligne), retourne false dans tous les autres cas
   */
  bool areNeighbor(List ligne, TableCellElement cell1, TableCellElement cell2) {
    if (ligne.contains(cell1) && ligne.contains(cell2) && cell1 != cell2) {
      TableCellElement middle = ligne[1];
      if (middle.contains(cell1) || middle.contains(cell2))
        return true;
    }
    return false;
  }
  
  /**
   * Retourne aléatoirement un élément de la liste
   */
  Object getRandomElement(List elements) {
    var r = new Random();
    int i = elements.length;
    if (i > 0)
      return elements[r.nextInt(i)];
    return null;
  }
  
  /**
   * Ajoute les éléments seulement si ceux-ci sont référencés, si aucune référence alors ajoute tout.
   */
  List addElementsRefferenced(List references, List elements) {
    if (elements.length > 0) {
      if (references.length > 0) {
        for(Object o in elements) {
          if (references.contains(o))
            references.add(o);
        }
      } else {
        for(Object o in elements) {
          references.add(o);
        }
      }
    }
    return references;
  }
  
  /**
   * Retire les éléments référencés
   */
  List removeElementsRefferenced(List references, List elements) {
    for (Object element in elements) {
      while(references.contains(element)) {
        references.remove(element);
      }
    }
    return references;
  }
  
  /**
   * Retourne la liste des éléments les plus référencés
   */
  List getMostRefferenced(List references) {
    List result = new List();
    int count = 0;
    int max = 0;
    for (Object reference in references) {
      count = numberOfInstance(references, reference);
      if (count > max) {
        result.clear();
        max = count;
        result.add(reference);
      } else if (count == max) {
        if (!result.contains(reference))
          result.add(reference);
      }
    }
    return result;
  }
  
  /**
   * Retourne une liste contenant tous les voisins de la cellule marqués à VIDE
   */
  List getFreeNeighbor(TableCellElement cell) {
    List possibilites = new List();
    List lignesCell = getLignesFromCell(cell);
    for(List ligne in lignesCell) {
      for (TableCellElement c in ligne) {
        if (areNeighbor(ligne, cell, c)) {
          if (!possibilites.contains(c) && getCellClass(c) == VIDE)
            possibilites.add(c);
        }
      }
    }
    
    return possibilites;
  }
  
  
  
  
  
  /**
   * Retourne true si c'est au joueur de joueur
   */
  bool isTourJoueur() {
    return (tour % 2 == 0);
  }
  
  /**
   * Incrémente le compteur de tour
   */
  void tourSuivant() {
    tour++;
    memory.addTable(table);
    manageMessage();
    
    if (tour >= 18) {
      List possibilitesIA = new List();
      List possibilitesJoueur = new List();
      
      for(List ligne in lignes) {
        for (TableCellElement cell in ligne) {
          if (getCellClass(cell) == IA) {
            for (TableCellElement c in getFreeNeighbor(cell)) {
              int count = 0;
              for (Mouvement mouvement in possibilitesIA) {
                if (mouvement.getDepart() == cell && mouvement.getArrive() == c)
                  count++;
              }
              if (count == 0)
                possibilitesIA.add(new Mouvement(cell, c));
            }
          }
          if (getCellClass(cell) == JOUEUR) {
            for (TableCellElement c in getFreeNeighbor(cell)) {
              int count = 0;
              for (Mouvement mouvement in possibilitesJoueur) {
                if (mouvement.getDepart() == cell && mouvement.getArrive() == c)
                  count++;
              }
              if (count == 0)
                possibilitesJoueur.add(new Mouvement(cell, c));
            }
          }
        }
      }
      
      if (possibilitesIA.length == 0 && nbrPiecesIA > 3 
          || possibilitesJoueur.length == 0 && nbrPiecesJoueur > 3) 
        phaseFinDePartie(true);
      else if (memory.threeTimesSameTable())
        phaseFinDePartie(false);
    }
  }
  
  /**
   * Manage la valeur du morris
   */
  bool getMorris() {
    return newMorris;
  }
  
  void setMorris(bool v) {
    newMorris = v;
    if (v)
      tourLastMorris = tour;
    manageMessage();
  }
  
  TableCellElement getCellToMove() {
    return cellToMove;
  }
  
  void setMouvementIA(Mouvement mouvement) {
    mouvementIA = mouvement;
    if (mouvementIA != null) {
      setCellToMove(mouvement.getDepart());
    }
    else if (mouvementIA == null)
      setCellToMove(null);
  }
  
  Mouvement getMouvementIA() {
    return mouvementIA;
  }
  
  void setCellToMove(TableCellElement cell) {
    TableCellElement temp = cellToMove;
    cellToMove = cell;
    
    if (temp != null) {
      if (getCellClass(temp) == JOUEUR_DEPLACE)
        setCellClass(temp, JOUEUR);
      else if (getCellClass(temp) == IA_DEPLACE)
        setCellClass(temp, IA);
    }

    if (cell != null && isTourJoueur())
      setCellClass(cell, JOUEUR_DEPLACE);
    else if (cell != null)
      setCellClass(cell, IA_DEPLACE);
  }
  
  /**
   * Change la classe de la cellule passée en paramettre 
   */
  void setCellClass(TableCellElement cell, String classe) {
    cell.classes.remove(VIDE);
    cell.classes.remove(JOUEUR);
    cell.classes.remove(JOUEUR_DEPLACE);
    cell.classes.remove(IA_DEPLACE);
    cell.classes.remove(IA);
    cell.classes.add(classe);
  }
  
  String getCellClass(TableCellElement cell) {
    return cell.classes.first;
  }
  
  /**
   * Manage l'affichage du prompteur
   */
  void manageMessage() {
    if (isTourJoueur()) {
      if (getMorris())
        message = MESSAGE_JOUEUR_MORRIS;
      else
        message = MESSAGE_JOUEUR;
    } else {
      if (getMorris())
        message = MESSAGE_IA_MORRIS;
      else
        message = MESSAGE_IA;
    }
  }
  
  /**
   * Méthode appelée lorsqu'un pion est supprimé
   */
  void enlevePion() {
    if (isTourJoueur()) {
      nbrPiecesIA--;
    } else {
      nbrPiecesJoueur--;
    }
    
    if (nbrPiecesIA < 3 || nbrPiecesJoueur < 3)
      phaseFinDePartie(false);
  }
  
  
  
  
  
  /**
   * Initialise les variables essentielles pour l'exécution de l'IA
   */
  void init(TableCellElement cell) {
    var t = table;
    TableRowElement row = cell.parent;
    table = row.parent;
    if (t == null) 
      buildLignes();
  }
  
  /**
   * Construit la liste de lignes du plateau
   */
  void buildLignes() {
    lignes.add(buildLigne(1,2,3));
    lignes.add(buildLigne(4,5,6));
    lignes.add(buildLigne(7,8,9));
    lignes.add(buildLigne(10,11,12));
    lignes.add(buildLigne(13,14,15));
    lignes.add(buildLigne(16,17,18));
    lignes.add(buildLigne(19,20,21));
    lignes.add(buildLigne(22,23,24));
    lignes.add(buildLigne(1,10,22));
    lignes.add(buildLigne(4,11,19));
    lignes.add(buildLigne(7,12,16));
    lignes.add(buildLigne(2,5,8));
    lignes.add(buildLigne(17,20,23));
    lignes.add(buildLigne(9,13,18));
    lignes.add(buildLigne(6,14,21));
    lignes.add(buildLigne(3,15,24));
  }
  
  /**
   * Construit une ligne à partir des id spécifiés
   */
  List buildLigne(int cell1, int cell2, int cell3) {
    List ligne = new List();
    ligne.add(getCell(cell1));
    ligne.add(getCell(cell2));
    ligne.add(getCell(cell3));
    return ligne;
  }
  
  /**
   * Retourne la cellue à partir de son id
   */
  TableCellElement getCell(int id) {
    for(TableRowElement row in table.children) {
      for (TableCellElement cell in row.children) {
        if (cell.id == id.toString())
          return cell;
      }
    }
  }
}