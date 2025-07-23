class Pokemon {
  final int pokedexNumber;
  final String name;
  final List<String> types;

  const Pokemon({
    required this.pokedexNumber,
    required this.name,
    required this.types,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pokemon &&
          runtimeType == other.runtimeType &&
          pokedexNumber == other.pokedexNumber;

  @override
  int get hashCode => pokedexNumber.hashCode;
}
