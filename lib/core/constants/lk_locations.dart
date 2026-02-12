class SriLankaLocationData {
  List<String> getProvinces() => [
    'Central',
    'Eastern', // newly added
    'North Central', // newly added
    'Northern',
    'North Western', // newly added
    'Sabaragamuwa', // newly added
    'Southern',
    'Uva', // newly added
    'Western',
  ];

  List<String> getDistricts(String province) {
    if (province == 'Central') {
      return ['Kandy', 'Matale', 'Nuwara Eliya'];
    }
    if (province == 'Eastern') {
      return ['Ampara', 'Batticaloa', 'Trincomalee'];
    }
    if (province == 'North Central') {
      return ['Anuradhapura', 'Polonnaruwa'];
    }
    if (province == 'Northern') {
      return ['Jaffna', 'Kilinochchi', 'Mannar', 'Mullaitivu', 'Vavuniya'];
    }
    if (province == 'North Western') {
      return ['Kurunegala', 'Puttalam'];
    }
    if (province == 'Sabaragamuwa') {
      return ['Kegalle', 'Ratnapura'];
    }
    if (province == 'Southern') {
      return ['Galle', 'Matara', 'Hambantota'];
    }
    if (province == 'Uva') {
      return ['Badulla', 'Monaragala'];
    }
    if (province == 'Western') {
      return ['Colombo', 'Gampaha', 'Kalutara'];
    }
    return [];
  }

  List<String> getCities(String province, String district) {
    switch (district) {
      case 'Kandy':
        return ['Kandy City', 'Peradeniya', 'Digana', 'Gampola', 'Katugastota'];
      case 'Matale':
        return ['Matale Town', 'Dambulla', 'Sigiriya', 'Nalanda'];
      case 'Nuwara Eliya':
        return [
          'Nuwara Eliya Town',
          'Hatton',
          'Talawakele',
          'Maskeliya',
          'Kothmale',
        ];

      case 'Colombo':
        return [
          'Colombo 01',
          'Kotte',
          'Dehiwala',
          'Moratuwa',
          'Mount Lavinia',
          'Wellawatte',
        ];
      case 'Gampaha':
        return ['Gampaha Town', 'Negombo', 'Wattala', 'Minuwangoda', 'Ja-Ela'];
      case 'Kalutara':
        return [
          'Kalutara North',
          'Panadura',
          'Horana',
          'Beruwala',
          'Bandaragama',
        ];

      case 'Galle':
        return [
          'Galle City',
          'Ambalangoda',
          'Hikkaduwa',
          'Elpitiya',
          'Baddegama',
        ];
      case 'Matara':
        return [
          'Matara Town',
          'Akuressa',
          'Weligama',
          'Deniyaya',
          'Devinuwara',
        ];
      case 'Hambantota':
        return [
          'Hambantota Town',
          'Tangalle',
          'Tissamaharama',
          'Beliatta',
          'Ambalantota',
        ];

      case 'Jaffna':
        return [
          'Jaffna City',
          'Point Pedro',
          'Chavakachcheri',
          'Kayts',
          'Nallur',
        ];
      case 'Kilinochchi':
        return ['Kilinochchi Town', 'Pallai', 'Poonakary'];
      case 'Mannar':
        return ['Mannar Town', 'Madhu', 'Manthai West', 'Musalai', 'Nanaddan'];
      case 'Mullaitivu':
        return [
          'Mullaitivu Town',
          'Maritimepattu',
          'Puthukkudiyiruppu',
          'Oddusuddan',
          'Welioya',
        ];
      case 'Vavuniya':
        return [
          'Vavuniya Town',
          'Vavuniya North',
          'Vavuniya South',
          'Vengalacheddikulam',
        ];

      case 'Ampara':
        return [
          'Ampara Town',
          'Dehiattakandiya',
          'Kalmunai',
          'Karativu',
          'Navithanveli',
          'Padiyathalawa',
          'Pottuvil',
          'Sammanthurai',
          'Uhana',
        ];
      case 'Batticaloa':
        return [
          'Batticaloa City',
          'Eravur',
          'Kattankudy',
          'Chenkalady',
          'Valachchenai',
        ];
      case 'Trincomalee':
        return [
          'Trincomalee City',
          'Kantalai',
          'Kinniya',
          'Muttur',
          'Morawewa (Sampur)',
          'Padavi Sri Pura',
          'Seruvila',
          'Thambalagamuwa',
        ];

      case 'Anuradhapura':
        return [
          'Anuradhapura City',
          'Padaviya',
          'Galenbindunuwewa',
          'Medawachchiya',
          'Thambuttegama',
          'Thalawa',
          'Nochchiyagama',
        ];
      case 'Polonnaruwa':
        return [
          'Polonnaruwa Town',
          'Hingurakgoda',
          'Medirigiriya',
          'Thamankaduwa',
          'Lankapura',
        ];

      case 'Kurunegala':
        return [
          'Kurunegala Town',
          'Kuliyapitiya',
          'Nikaweratiya',
          'Pannala',
          'Mawathagama',
        ];
      case 'Puttalam':
        return [
          'Puttalam Town',
          'Chilaw',
          'Kuliyapitiya',
          'Anamaduwa',
          'Wennappuwa',
          'Karuwalagaswewa',
        ];

      case 'Kegalle':
        return [
          'Kegalle Town',
          'Ruwanwella',
          'Mawanella',
          'Yatinuwara',
          'Aranayaka',
        ];
      case 'Ratnapura':
        return [
          'Ratnapura Town',
          'Balangoda',
          'Embilipitiya',
          'Godakawela',
          'Pelmadulla',
        ];

      case 'Badulla':
        return [
          'Badulla Town',
          'Bandarawela',
          'Hali-Ela',
          'Passara',
          'Mahiyanganaya',
        ];
      case 'Monaragala':
        return [
          'Monaragala Town',
          'Bibile',
          'Buttala',
          'Siyambalanduwa',
          'Wellawaya',
          'Medagama',
        ];

      default:
        return [];
    }
  }
}
