import 'package:flutter/material.dart';

class PackingTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<TemplateItem> items;

  const PackingTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.items,
  });
}

class TemplateItem {
  final String name;
  final String category;

  const TemplateItem({
    required this.name,
    required this.category,
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'category': category,
    };
  }
}

class PackingTemplates {
  static const List<PackingTemplate> all = [
    PackingTemplate(
      id: 'praia',
      name: 'Viagem de Praia',
      description: 'Itens essenciais para aproveitar o sol e o mar',
      icon: Icons.beach_access,
      items: [
        // Roupas
        TemplateItem(name: 'Maiô/Sunga', category: 'Roupas'),
        TemplateItem(name: 'Biquíni extra', category: 'Roupas'),
        TemplateItem(name: 'Camisetas leves', category: 'Roupas'),
        TemplateItem(name: 'Shorts', category: 'Roupas'),
        TemplateItem(name: 'Vestido de praia', category: 'Roupas'),
        TemplateItem(name: 'Saída de praia', category: 'Roupas'),
        TemplateItem(name: 'Roupa para jantar', category: 'Roupas'),
        TemplateItem(name: 'Pijama', category: 'Roupas'),
        TemplateItem(name: 'Roupa íntima', category: 'Roupas'),

        // Calçados
        TemplateItem(name: 'Chinelos', category: 'Calçados'),
        TemplateItem(name: 'Sandálias', category: 'Calçados'),
        TemplateItem(name: 'Tênis confortável', category: 'Calçados'),

        // Acessórios
        TemplateItem(name: 'Chapéu/Boné', category: 'Acessórios'),
        TemplateItem(name: 'Óculos de sol', category: 'Acessórios'),
        TemplateItem(name: 'Toalha de praia', category: 'Acessórios'),
        TemplateItem(name: 'Bolsa de praia', category: 'Acessórios'),
        TemplateItem(name: 'Canga', category: 'Acessórios'),

        // Higiene
        TemplateItem(name: 'Protetor solar', category: 'Higiene'),
        TemplateItem(name: 'Pós-sol', category: 'Higiene'),
        TemplateItem(name: 'Repelente', category: 'Higiene'),
        TemplateItem(name: 'Shampoo e condicionador', category: 'Higiene'),
        TemplateItem(name: 'Sabonete', category: 'Higiene'),
        TemplateItem(name: 'Escova de dentes e pasta', category: 'Higiene'),
        TemplateItem(name: 'Desodorante', category: 'Higiene'),

        // Eletrônicos
        TemplateItem(name: 'Celular e carregador', category: 'Eletrônicos'),
        TemplateItem(name: 'Câmera à prova d\'água', category: 'Eletrônicos'),
        TemplateItem(name: 'Power bank', category: 'Eletrônicos'),

        // Documentos
        TemplateItem(name: 'RG/CNH', category: 'Documentos'),
        TemplateItem(name: 'Cartão de crédito', category: 'Documentos'),
        TemplateItem(name: 'Dinheiro', category: 'Documentos'),
        TemplateItem(name: 'Reservas impressas', category: 'Documentos'),
      ],
    ),
    PackingTemplate(
      id: 'montanha',
      name: 'Viagem de Montanha',
      description: 'Equipamentos para trilhas e clima frio',
      icon: Icons.terrain,
      items: [
        // Roupas
        TemplateItem(name: 'Jaqueta impermeável', category: 'Roupas'),
        TemplateItem(name: 'Casaco de frio', category: 'Roupas'),
        TemplateItem(name: 'Calça térmica', category: 'Roupas'),
        TemplateItem(name: 'Camisetas térmicas', category: 'Roupas'),
        TemplateItem(name: 'Calça de trilha', category: 'Roupas'),
        TemplateItem(name: 'Meias térmicas', category: 'Roupas'),
        TemplateItem(name: 'Luvas', category: 'Roupas'),
        TemplateItem(name: 'Gorro/Touca', category: 'Roupas'),

        // Calçados
        TemplateItem(name: 'Bota de trilha', category: 'Calçados'),
        TemplateItem(name: 'Tênis extra', category: 'Calçados'),
        TemplateItem(name: 'Chinelo para descanso', category: 'Calçados'),

        // Acessórios
        TemplateItem(name: 'Mochila de trilha', category: 'Acessórios'),
        TemplateItem(name: 'Garrafa térmica', category: 'Acessórios'),
        TemplateItem(name: 'Lanterna/Headlamp', category: 'Acessórios'),
        TemplateItem(name: 'Bastão de caminhada', category: 'Acessórios'),
        TemplateItem(name: 'Óculos de sol', category: 'Acessórios'),
        TemplateItem(name: 'Protetor labial', category: 'Acessórios'),

        // Higiene
        TemplateItem(name: 'Protetor solar', category: 'Higiene'),
        TemplateItem(name: 'Hidratante corporal', category: 'Higiene'),
        TemplateItem(name: 'Kit higiene básico', category: 'Higiene'),

        // Medicamentos
        TemplateItem(name: 'Kit primeiros socorros', category: 'Medicamentos'),
        TemplateItem(name: 'Remédio para altitude', category: 'Medicamentos'),
        TemplateItem(name: 'Analgésico', category: 'Medicamentos'),

        // Eletrônicos
        TemplateItem(name: 'Celular e carregador', category: 'Eletrônicos'),
        TemplateItem(name: 'GPS/Bússola', category: 'Eletrônicos'),
        TemplateItem(name: 'Power bank', category: 'Eletrônicos'),

        // Documentos
        TemplateItem(name: 'Documentos pessoais', category: 'Documentos'),
        TemplateItem(name: 'Seguro viagem', category: 'Documentos'),
      ],
    ),
    PackingTemplate(
      id: 'cidade',
      name: 'Viagem Urbana',
      description: 'Essenciais para explorar cidades',
      icon: Icons.location_city,
      items: [
        // Roupas
        TemplateItem(name: 'Calça jeans', category: 'Roupas'),
        TemplateItem(name: 'Camisetas', category: 'Roupas'),
        TemplateItem(name: 'Camisa social', category: 'Roupas'),
        TemplateItem(name: 'Vestido casual', category: 'Roupas'),
        TemplateItem(name: 'Jaqueta leve', category: 'Roupas'),
        TemplateItem(name: 'Roupa íntima', category: 'Roupas'),
        TemplateItem(name: 'Pijama', category: 'Roupas'),

        // Calçados
        TemplateItem(name: 'Tênis confortável', category: 'Calçados'),
        TemplateItem(name: 'Sapato social', category: 'Calçados'),
        TemplateItem(name: 'Sandália', category: 'Calçados'),

        // Acessórios
        TemplateItem(name: 'Mochila/Bolsa', category: 'Acessórios'),
        TemplateItem(name: 'Óculos de sol', category: 'Acessórios'),
        TemplateItem(name: 'Guarda-chuva', category: 'Acessórios'),
        TemplateItem(name: 'Garrafa de água', category: 'Acessórios'),

        // Higiene
        TemplateItem(name: 'Kit higiene completo', category: 'Higiene'),
        TemplateItem(name: 'Perfume', category: 'Higiene'),
        TemplateItem(name: 'Maquiagem', category: 'Higiene'),

        // Eletrônicos
        TemplateItem(name: 'Celular e carregador', category: 'Eletrônicos'),
        TemplateItem(name: 'Câmera fotográfica', category: 'Eletrônicos'),
        TemplateItem(name: 'Fone de ouvido', category: 'Eletrônicos'),
        TemplateItem(name: 'Adaptador universal', category: 'Eletrônicos'),

        // Documentos
        TemplateItem(name: 'RG/Passaporte', category: 'Documentos'),
        TemplateItem(name: 'Cartões', category: 'Documentos'),
        TemplateItem(name: 'Mapas/Guias', category: 'Documentos'),
      ],
    ),
    PackingTemplate(
      id: 'negocios',
      name: 'Viagem de Negócios',
      description: 'Itens profissionais e corporativos',
      icon: Icons.business_center,
      items: [
        // Roupas
        TemplateItem(name: 'Terno/Blazer', category: 'Roupas'),
        TemplateItem(name: 'Camisas sociais', category: 'Roupas'),
        TemplateItem(name: 'Calças sociais', category: 'Roupas'),
        TemplateItem(name: 'Gravatas', category: 'Roupas'),
        TemplateItem(name: 'Vestido executivo', category: 'Roupas'),
        TemplateItem(name: 'Roupa casual', category: 'Roupas'),

        // Calçados
        TemplateItem(name: 'Sapato social', category: 'Calçados'),
        TemplateItem(name: 'Sapato casual', category: 'Calçados'),

        // Acessórios
        TemplateItem(name: 'Pasta executiva', category: 'Acessórios'),
        TemplateItem(name: 'Relógio', category: 'Acessórios'),
        TemplateItem(name: 'Cinto', category: 'Acessórios'),

        // Eletrônicos
        TemplateItem(name: 'Notebook', category: 'Eletrônicos'),
        TemplateItem(name: 'Carregador notebook', category: 'Eletrônicos'),
        TemplateItem(name: 'Celular e carregador', category: 'Eletrônicos'),
        TemplateItem(name: 'Mouse', category: 'Eletrônicos'),
        TemplateItem(name: 'Pen drive', category: 'Eletrônicos'),
        TemplateItem(name: 'Fone de ouvido', category: 'Eletrônicos'),

        // Documentos
        TemplateItem(name: 'Documentos pessoais', category: 'Documentos'),
        TemplateItem(name: 'Cartões corporativos', category: 'Documentos'),
        TemplateItem(name: 'Cartões de visita', category: 'Documentos'),
        TemplateItem(name: 'Agenda/Caderno', category: 'Documentos'),
        TemplateItem(name: 'Canetas', category: 'Documentos'),

        // Higiene
        TemplateItem(name: 'Kit higiene executivo', category: 'Higiene'),
        TemplateItem(name: 'Perfume', category: 'Higiene'),
      ],
    ),
    PackingTemplate(
      id: 'camping',
      name: 'Camping/Aventura',
      description: 'Equipamentos para acampamento',
      icon: Icons.nature_people,
      items: [
        // Equipamentos
        TemplateItem(name: 'Barraca', category: 'Outros'),
        TemplateItem(name: 'Saco de dormir', category: 'Outros'),
        TemplateItem(name: 'Isolante térmico', category: 'Outros'),
        TemplateItem(name: 'Fogareiro', category: 'Outros'),
        TemplateItem(name: 'Panelas camping', category: 'Outros'),
        TemplateItem(name: 'Talheres', category: 'Outros'),
        TemplateItem(name: 'Corda', category: 'Outros'),
        TemplateItem(name: 'Faca multiuso', category: 'Outros'),

        // Roupas
        TemplateItem(name: 'Roupas térmicas', category: 'Roupas'),
        TemplateItem(name: 'Jaqueta impermeável', category: 'Roupas'),
        TemplateItem(name: 'Calça de trilha', category: 'Roupas'),
        TemplateItem(name: 'Meias extras', category: 'Roupas'),

        // Calçados
        TemplateItem(name: 'Bota de trilha', category: 'Calçados'),
        TemplateItem(name: 'Sandália', category: 'Calçados'),

        // Acessórios
        TemplateItem(name: 'Mochila grande', category: 'Acessórios'),
        TemplateItem(name: 'Lanterna', category: 'Acessórios'),
        TemplateItem(name: 'Pilhas extras', category: 'Acessórios'),
        TemplateItem(name: 'Cantil', category: 'Acessórios'),
        TemplateItem(name: 'Isqueiro/Fósforos', category: 'Acessórios'),

        // Medicamentos
        TemplateItem(name: 'Kit primeiros socorros', category: 'Medicamentos'),
        TemplateItem(name: 'Repelente', category: 'Medicamentos'),
        TemplateItem(name: 'Protetor solar', category: 'Medicamentos'),

        // Higiene
        TemplateItem(name: 'Sabonete biodegradável', category: 'Higiene'),
        TemplateItem(name: 'Papel higiênico', category: 'Higiene'),
        TemplateItem(name: 'Toalha de secagem rápida', category: 'Higiene'),
      ],
    ),
    PackingTemplate(
      id: 'internacional',
      name: 'Viagem Internacional',
      description: 'Essenciais para viagens ao exterior',
      icon: Icons.flight,
      items: [
        // Documentos
        TemplateItem(name: 'Passaporte', category: 'Documentos'),
        TemplateItem(name: 'Visto', category: 'Documentos'),
        TemplateItem(name: 'Seguro viagem', category: 'Documentos'),
        TemplateItem(name: 'Carteira de vacinação', category: 'Documentos'),
        TemplateItem(name: 'Cópias dos documentos', category: 'Documentos'),
        TemplateItem(name: 'Cartões internacionais', category: 'Documentos'),
        TemplateItem(name: 'Moeda local', category: 'Documentos'),

        // Eletrônicos
        TemplateItem(name: 'Adaptador universal', category: 'Eletrônicos'),
        TemplateItem(name: 'Celular desbloqueado', category: 'Eletrônicos'),
        TemplateItem(name: 'Carregadores', category: 'Eletrônicos'),
        TemplateItem(name: 'Power bank', category: 'Eletrônicos'),

        // Roupas
        TemplateItem(name: 'Roupas variadas', category: 'Roupas'),
        TemplateItem(name: 'Jaqueta', category: 'Roupas'),
        TemplateItem(name: 'Roupa confortável voo', category: 'Roupas'),

        // Acessórios
        TemplateItem(name: 'Mala de bordo', category: 'Acessórios'),
        TemplateItem(name: 'Cadeado TSA', category: 'Acessórios'),
        TemplateItem(name: 'Máscara de dormir', category: 'Acessórios'),
        TemplateItem(name: 'Travesseiro de pescoço', category: 'Acessórios'),

        // Higiene
        TemplateItem(name: 'Kit higiene viagem', category: 'Higiene'),
        TemplateItem(name: 'Remédios pessoais', category: 'Medicamentos'),
        TemplateItem(name: 'Receitas médicas', category: 'Medicamentos'),
      ],
    ),
  ];

  static PackingTemplate? getById(String id) {
    try {
      return all.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }
}

// PELO AMOR DE DEUS, NÃO MEXE NISSO 