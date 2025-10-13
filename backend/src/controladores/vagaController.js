const Vaga = require('../modelos/Vaga');

// Exemplo de controlador para criar uma vaga
exports.criarVaga = async (req, res) => {
    try {
        const novaVaga = await Vaga.create(req.body);
        res.status(201).json(novaVaga);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Exemplo de controlador para listar vagas
exports.listarVagas = async (req, res) => {
    try {
        const vagas = await Vaga.findAll();
        res.status(200).json(vagas);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
