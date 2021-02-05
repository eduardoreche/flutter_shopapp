import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/products.dart';
import '../providers/product.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product';

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _edittedProduct = Product(
    id: null,
    title: '',
    price: 0,
    description: '',
    imageUrl: '',
  );
  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
    'imageUrl': '',
  };
  var _isInit = false;
  var _isLoading = false;

  @override
  void initState() {
    _imageUrlFocusNode.addListener(_updateImageUrl);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      final productId = ModalRoute.of(context).settings.arguments as String;
      if (productId != null) {
        _edittedProduct = Provider.of<Products>(context).findById(productId);
        _initValues = {
          'title': _edittedProduct.title,
          'description': _edittedProduct.description,
          'price': _edittedProduct.price.toString(),
          'imageUrl': '',
        };

        _imageUrlController.text = _edittedProduct.imageUrl;
      }
    }

    _isInit = true;
    super.didChangeDependencies();
  }

  void _updateImageUrl() {
    if (!_imageUrlFocusNode.hasFocus) {
      if (_imageUrlController.text.isEmpty ||
          !_imageUrlController.text.startsWith('http')) {
        return;
      }
      setState(() {});
    }
  }

  void _saveForm() {
    final isValid = _form.currentState.validate();
    if (!isValid) return;

    _form.currentState.save();

    _toggleIsLoading();

    var provider = Provider.of<Products>(context, listen: false);
    if (_edittedProduct.id == null) {
      provider.addProduct(_edittedProduct).catchError((error) {
        return showDialog<Null>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('An error occurred'),
            content: Text('Something went wrong!!'),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Okay'),
              ),
            ],
          ),
        );
      }).then((_) {
        _toggleIsLoading();
        Navigator.of(context).pop();
      });
    } else {
      provider.updateProduct(_edittedProduct);
      Navigator.of(context).pop();
    }
  }

  void _toggleIsLoading() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateImageUrl);
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlFocusNode.dispose();
    _imageUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _initValues['title'],
                        decoration: InputDecoration(labelText: 'Title'),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_priceFocusNode),
                        validator: (value) =>
                            value.isEmpty ? 'Please provide a value' : null,
                        onSaved: (value) {
                          _edittedProduct = Product(
                            id: _edittedProduct.id,
                            isFavorite: _edittedProduct.isFavorite,
                            title: value,
                            price: _edittedProduct.price,
                            description: _edittedProduct.description,
                            imageUrl: _edittedProduct.imageUrl,
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: _initValues['price'],
                        decoration: InputDecoration(labelText: 'Price'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        focusNode: _priceFocusNode,
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode),
                        validator: (value) {
                          if (value.isEmpty) return 'Please enter a price';
                          if (double.tryParse(value) == null)
                            return 'Please enter a valid number';
                          if (double.parse(value) <= 0)
                            return 'Please enter a number greater than zero';

                          return null;
                        },
                        onSaved: (value) {
                          _edittedProduct = Product(
                            id: _edittedProduct.id,
                            isFavorite: _edittedProduct.isFavorite,
                            title: _edittedProduct.title,
                            price: double.parse(value),
                            description: _edittedProduct.description,
                            imageUrl: _edittedProduct.imageUrl,
                          );
                        },
                      ),
                      TextFormField(
                        initialValue: _initValues['description'],
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        focusNode: _descriptionFocusNode,
                        validator: (value) =>
                            value.isEmpty ? 'Please enter a description' : null,
                        onSaved: (value) {
                          _edittedProduct = Product(
                            id: _edittedProduct.id,
                            isFavorite: _edittedProduct.isFavorite,
                            title: _edittedProduct.title,
                            price: _edittedProduct.price,
                            description: value,
                            imageUrl: _edittedProduct.imageUrl,
                          );
                        },
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(
                              top: 8,
                              right: 10,
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(
                              width: 1,
                              color: Colors.grey,
                            )),
                            child: _imageUrlController.text.isEmpty
                                ? Text('Enter a URL')
                                : FittedBox(
                                    child: Image.network(
                                      _imageUrlController.text,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Image URL'),
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              controller: _imageUrlController,
                              focusNode: _imageUrlFocusNode,
                              onFieldSubmitted: (_) => _saveForm(),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter a image URL';
                                }
                                // if (!value.startsWith('http')) {
                                //   return 'Please enter a valid URL';
                                // }

                                return null;
                              },
                              onSaved: (value) {
                                _edittedProduct = Product(
                                  id: _edittedProduct.id,
                                  isFavorite: _edittedProduct.isFavorite,
                                  title: _edittedProduct.title,
                                  price: _edittedProduct.price,
                                  description: _edittedProduct.description,
                                  imageUrl: value,
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
