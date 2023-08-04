import 'package:objectbox/objectbox.dart';

@Entity() // Annotate a Dart class to create a box
class Person {
  @Id()
  int id;
  String name;
  String tpPessoa;
  int cpfcnpj;

  Person(
      {this.id = 0, //s Random().nextDouble().toString(),
      required this.name,
      required this.tpPessoa,
      required this.cpfcnpj});
}
