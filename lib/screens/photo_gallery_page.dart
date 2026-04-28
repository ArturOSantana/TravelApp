import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/photo_gallery.dart';
import '../services/storage_service.dart';

class PhotoGalleryPage extends StatefulWidget {
  final String tripId;
  final String tripName;

  const PhotoGalleryPage({
    Key? key,
    required this.tripId,
    required this.tripName,
  }) : super(key: key);

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _selectedFolder;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galeria - ${widget.tripName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGallery,
            tooltip: 'Compartilhar Galeria',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFolderSelector(),
          if (_isUploading) _buildUploadProgress(),
          Expanded(child: _buildPhotoGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPhotos,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Adicionar Fotos'),
      ),
    );
  }

  Widget _buildFolderSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PhotoFolders.all.length,
        itemBuilder: (context, index) {
          final folder = PhotoFolders.all[index];
          final isSelected = _selectedFolder == folder;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '${PhotoFolders.getIcon(folder)} $folder',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFolder = selected ? folder : null;
                });
              },
              selectedColor: Colors.deepPurple,
              backgroundColor: Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepPurple.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enviando fotos...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: _uploadProgress),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('photo_albums')
          .where('tripId', isEqualTo: widget.tripId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final albums = snapshot.data!.docs
            .map((doc) => PhotoAlbum.fromFirestore(doc))
            .toList();

        // Filtrar por pasta se selecionada
        List<PhotoItem> allPhotos = [];
        for (var album in albums) {
          if (_selectedFolder == null || album.folderName == _selectedFolder) {
            allPhotos.addAll(album.photos);
          }
        }

        if (allPhotos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _selectedFolder == null
                      ? 'Nenhuma foto ainda'
                      : 'Nenhuma foto em "$_selectedFolder"',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toque no botão + para adicionar',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Ordenar por data (mais recentes primeiro)
        allPhotos.sort((a, b) => b.takenAt.compareTo(a.takenAt));

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: allPhotos.length,
          itemBuilder: (context, index) {
            final photo = allPhotos[index];
            return _buildPhotoCard(photo, albums);
          },
        );
      },
    );
  }

  Widget _buildPhotoCard(PhotoItem photo, List<PhotoAlbum> albums) {
    return GestureDetector(
      onTap: () => _viewPhoto(photo, albums),
      onLongPress: () => _showPhotoOptions(photo, albums),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: photo.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            ),
          ),
          if (photo.isPublic)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.public, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _viewPhoto(PhotoItem photo, List<PhotoAlbum> albums) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PhotoViewPage(photo: photo, albums: albums, tripId: widget.tripId),
      ),
    );
  }

  void _showPhotoOptions(PhotoItem photo, List<PhotoAlbum> albums) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                photo.isPublic ? Icons.lock : Icons.public,
                color: Colors.deepPurple,
              ),
              title: Text(photo.isPublic ? 'Tornar Privada' : 'Tornar Pública'),
              onTap: () {
                Navigator.pop(context);
                _togglePhotoVisibility(photo, albums);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(context);
                Share.share(
                  'Confira esta foto da minha viagem!\n${photo.url}',
                  subject: 'Foto de Viagem',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Excluir'),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(photo, albums);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhotos() async {
    // Mostrar diálogo para selecionar pasta
    final folder = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecione a Pasta'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: PhotoFolders.all.length,
            itemBuilder: (context, index) {
              final folder = PhotoFolders.all[index];
              return ListTile(
                leading: Text(
                  PhotoFolders.getIcon(folder),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(folder),
                onTap: () => Navigator.pop(context, folder),
              );
            },
          ),
        ),
      ),
    );

    if (folder == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Selecionar múltiplas fotos
      final photos = await StorageService.pickMultiplePhotos();
      if (photos.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      // Upload das fotos
      final urls = await StorageService.uploadMultiplePhotos(
        photos: photos,
        tripId: widget.tripId,
        folder: folder.toLowerCase().replaceAll(' ', '_'),
        onProgress: (current, total) {
          setState(() {
            _uploadProgress = current / total;
          });
        },
      );

      // Criar itens de foto
      final photoItems = urls.map((url) {
        return PhotoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: url,
          thumbnailUrl: url,
          takenAt: DateTime.now(),
          isPublic: false,
        );
      }).toList();

      // Buscar ou criar álbum
      final albumQuery = await _db
          .collection('photo_albums')
          .where('tripId', isEqualTo: widget.tripId)
          .where('folderName', isEqualTo: folder)
          .limit(1)
          .get();

      if (albumQuery.docs.isEmpty) {
        // Criar novo álbum
        await _db.collection('photo_albums').add({
          'tripId': widget.tripId,
          'folderName': folder,
          'photos': photoItems.map((p) => p.toMap()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Adicionar ao álbum existente
        final albumDoc = albumQuery.docs.first;
        final album = PhotoAlbum.fromFirestore(albumDoc);
        final updatedPhotos = [...album.photos, ...photoItems];

        await albumDoc.reference.update({
          'photos': updatedPhotos.map((p) => p.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${photos.length} foto(s) adicionada(s)!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar fotos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _togglePhotoVisibility(
    PhotoItem photo,
    List<PhotoAlbum> albums,
  ) async {
    try {
      // Encontrar o álbum que contém a foto
      for (var album in albums) {
        final photoIndex = album.photos.indexWhere((p) => p.id == photo.id);
        if (photoIndex != -1) {
          final updatedPhotos = List<PhotoItem>.from(album.photos);
          updatedPhotos[photoIndex] = photo.copyWith(isPublic: !photo.isPublic);

          await _db.collection('photo_albums').doc(album.id).update({
            'photos': updatedPhotos.map((p) => p.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  photo.isPublic
                      ? 'Foto agora é privada'
                      : 'Foto agora é pública',
                ),
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePhoto(PhotoItem photo, List<PhotoAlbum> albums) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Foto'),
        content: const Text('Tem certeza que deseja excluir esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Deletar do Storage
      await StorageService.deletePhoto(photo.url);

      // Remover do Firestore
      for (var album in albums) {
        final photoIndex = album.photos.indexWhere((p) => p.id == photo.id);
        if (photoIndex != -1) {
          final updatedPhotos = List<PhotoItem>.from(album.photos)
            ..removeAt(photoIndex);

          await _db.collection('photo_albums').doc(album.id).update({
            'photos': updatedPhotos.map((p) => p.toMap()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto excluída com sucesso'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareGallery() {
    final albumUrl =
        'https://travel-app-tcc.web.app/album.html?tripId=${widget.tripId}';
    Share.share(
      'Confira a galeria da minha viagem "${widget.tripName}"!\n$albumUrl',
      subject: 'Galeria de Viagem',
    );
  }
}

// Tela de visualização de foto individual
class PhotoViewPage extends StatelessWidget {
  final PhotoItem photo;
  final List<PhotoAlbum> albums;
  final String tripId;

  const PhotoViewPage({
    Key? key,
    required this.photo,
    required this.albums,
    required this.tripId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                'Confira esta foto!\n${photo.url}',
                subject: 'Foto de Viagem',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: photo.url,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
      bottomNavigationBar: photo.caption != null || photo.location != null
          ? Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.caption != null)
                    Text(
                      photo.caption!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  if (photo.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          photo.location!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          : null,
    );
  }
}

