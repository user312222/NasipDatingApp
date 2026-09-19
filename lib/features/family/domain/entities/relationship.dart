/// FR-8.2: how the guardian relates to the single account they're
/// linking to.
enum Relationship { anne, baba, abla, agabey, teyze, dayi, diger }

extension RelationshipLabel on Relationship {
  String get label => switch (this) {
    Relationship.anne => 'Anne',
    Relationship.baba => 'Baba',
    Relationship.abla => 'Abla',
    Relationship.agabey => 'Ağabey',
    Relationship.teyze => 'Teyze',
    Relationship.dayi => 'Dayı',
    Relationship.diger => 'Diğer',
  };
}
