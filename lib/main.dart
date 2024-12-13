import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'database_helper.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ContactListScreen(),
    );
  }
}

class ContactListScreen extends StatefulWidget {
  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // Carregar os contatos do banco de dados
  Future<void> _loadContacts() async {
    final contacts = await DatabaseHelper.instance.getContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  // Excluir um contato
  Future<void> _deleteContact(int id) async {
    await DatabaseHelper.instance.deleteContact(id);
    _loadContacts();

    // Mostrar a mensagem após a exclusão
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contato deletado.')),
    );
  }

  // Exibir a tela de confirmação antes de excluir
  Future<void> _confirmDeleteContact(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Exclusão'),
          content: Text('Você tem certeza que deseja excluir este contato?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Fechar o diálogo
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteContact(id);
                Navigator.of(context).pop();  // Fechar o diálogo
              },
              child: Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  // Navegar para a tela de cadastro/edição
  Future<void> _navigateToAddContactScreen(Contact? contact) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(contact: contact),
      ),
    );
    if (result != null) {
      _loadContacts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contact == null ? 'Contato adicionado.' : 'Edição concluída.')),
      );
    }
  }

  // Navegar para a tela de visualização do contato
  void _navigateToContactDetailScreen(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lista de Contatos')),
      body: ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return ListTile(
            title: Text(contact.name),
            subtitle: Text('${contact.email}\n${contact.phone}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _navigateToAddContactScreen(contact), // Ir para a tela de edição
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeleteContact(contact.id!), // Confirmar exclusão
                ),
              ],
            ),
            onTap: () => _navigateToContactDetailScreen(contact), // Visualizar detalhes
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddContactScreen(null),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddContactScreen extends StatefulWidget {
  final Contact? contact;

  AddContactScreen({this.contact});

  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _phoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _emailController.text = widget.contact!.email;
      _phoneController.text = widget.contact!.phone;
    }
  }

  // Validação de E-mail
  bool _isEmailValid(String email) {
    // Verifica se o e-mail contém o "@" e ".com"
    return email.contains('@') && email.contains('.com');
  }

  // Validação de Telefone
  bool _isPhoneValid(String phone) {
    // Verifica se o telefone tem 15 caracteres (formato (XX) XXXXX-XXXX)
    return phone.length == 15;
  }

  // Salvar ou atualizar contato
  Future<void> _saveContact() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;

    if (!_isEmailValid(email)) {
      setState(() {
        _emailError = "E-mail inválido. Verifique o formato.";
      });
      return;
    } else {
      setState(() {
        _emailError = null;
      });
    }

    if (!_isPhoneValid(phone)) {
      setState(() {
        _phoneError = "Telefone inválido. Verifique o formato.";
      });
      return;
    } else {
      setState(() {
        _phoneError = null;
      });
    }

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      return;
    }

    final contact = Contact(name: name, email: email, phone: phone);

    if (widget.contact == null) {
      await DatabaseHelper.instance.insertContact(contact);
    } else {
      contact.id = widget.contact!.id;
      await DatabaseHelper.instance.updateContact(contact);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contact == null ? 'Adicionar Contato' : 'Editar Contato')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  } else if (!_isEmailValid(value)) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              if (_emailError != null)
                Text(
                  _emailError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              TextFormField(
                controller: _phoneController,
                inputFormatters: [_phoneFormatter],
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  } else if (!_isPhoneValid(value)) {
                    return 'Telefone inválido';
                  }
                  return null;
                },
              ),
              if (_phoneError != null)
                Text(
                  _phoneError!,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveContact,
                child: Text(widget.contact == null ? 'Cadastrar' : 'Atualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela de visualização do contato
class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  ContactDetailScreen({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes do Contato')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bordas arredondadas
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Ajustando o padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Garantindo que o Column não ocupe mais espaço do que o necessário
                children: [
                  Text(
                    'Nome: ${contact.name}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4), // Reduzindo o espaço entre os textos
                  Text(
                    'E-mail: ${contact.email}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 4), // Reduzindo o espaço entre os textos
                  Text(
                    'Telefone: ${contact.phone}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
