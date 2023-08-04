import 'package:objectbox/objectbox.dart';

@Entity() // Annotate a Dart class to create a box
class Usuario {
  @Id()
  int id;
  String tpGrupo; //1 admin - 2 usuario - 3 consulta
  String nome;
  String senha;

  Usuario(
      {this.id = 0,
      required this.tpGrupo,
      required this.nome,
      required this.senha});
}
