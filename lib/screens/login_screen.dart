import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/components/textinput_component.dart';
import 'package:smarttask/utils/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SMART TASK',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Sign in',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(
                height: 20,
              ),
            
              TextInput(hintText: 'Email address', prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress, fillColor: Colors.white,),
              const SizedBox(
                height: 20,),
            TextInput(hintText: 'Password', obscureText: true, prefixIcon: Icons.lock, keyboardType: TextInputType.numberWithOptions(decimal: false),),
             
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  context.go('/home');
                },
                style: CustomStyles.buttonStyle,
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
