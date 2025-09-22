const express = require('express');
const router = express.Router();
const pool = require('./Database'); // mysql2/promise

// =====================
// GET /equipments
// =====================
router.get('/equipments', async (req, res) => {
  try {
    const [results] = await pool.query('SELECT * FROM Equipments');
    res.json(results);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// =====================
// POST /equipments
// เพิ่มอุปกรณ์ใหม่
// =====================
router.post('/add/equipments', async (req, res) => {
  const { equipment_name, quantity } = req.body;
  if (!equipment_name || quantity == null) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  try {
    await pool.query('INSERT INTO Equipments (equipment_name, quantity) VALUES (?, ?)', [equipment_name, quantity]);
    const [results] = await pool.query('SELECT * FROM Equipments');
    res.json({ message: 'Equipment added', equipments: results });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// =====================
// PUT /equipments/:id
// แก้ไขอุปกรณ์
// =====================
router.put('/equipments/:id', async (req, res) => {
  const { id } = req.params;
  const { equipment_name, quantity } = req.body;

  try {
    await pool.query('UPDATE Equipments SET equipment_name = ?, quantity = ? WHERE id = ?', [equipment_name, quantity, id]);
    const [results] = await pool.query('SELECT * FROM Equipments');
    res.json({ message: 'Equipment updated', equipments: results });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

// =====================
// DELETE /equipments/:id
// ลบอุปกรณ์
// =====================
router.delete('/equipments/:id', async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query('DELETE FROM Equipments WHERE id = ?', [id]);
    const [results] = await pool.query('SELECT * FROM Equipments');
    res.json({ message: 'Equipment deleted', equipments: results });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
