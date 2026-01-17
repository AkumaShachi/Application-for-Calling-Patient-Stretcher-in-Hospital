const express = require('express');
const router = express.Router();
const pool = require('./Database');

// Delete case (Admin only)
router.delete('/cases/:caseId', async (req, res) => {
    const { caseId } = req.params;
    try {
        // Restore items before delete (Optional but good practice)
        // For simplicity in single delete we might skip, but let's try to restore if possible.
        // Or just keep existing logic for single delete to avoid breaking if not requested.
        // Existing logic:
        await pool.query('DELETE FROM caseequipments WHERE case_id = ?', [caseId]);
        const [result] = await pool.query('DELETE FROM cases WHERE case_id = ?', [caseId]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Case not found' });
        }

        res.json({ message: 'Case deleted successfully' });
    } catch (error) {
        console.error("Error deleting case:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Delete SELECTED cases (Admin)
router.post('/admin/cases/delete/list', async (req, res) => {
    const { caseIds } = req.body; // Expect array of integers/strings
    if (!caseIds || !Array.isArray(caseIds) || caseIds.length === 0) {
        return res.status(400).json({ message: 'No cases selected' });
    }

    const connection = await pool.getConnection();
    try {
        await connection.beginTransaction();

        // Convert to string for SQL IN clause? OR use safe logic.
        // We can pass array directly to query in mysql2 '?' placeholder if we use "IN (?)"
        
        // 1. Restore Stretcher Quantities
        await connection.query(`
            UPDATE stretchertypes s
            JOIN (
                SELECT str_type_id, COUNT(*) as count 
                FROM cases 
                WHERE case_id IN (?) 
                GROUP BY str_type_id
            ) c ON s.str_type_id = c.str_type_id
            SET s.str_quantity = s.str_quantity + c.count
        `, [caseIds]);

        // 2. Restore Equipment Quantities
        await connection.query(`
            UPDATE equipments e
            JOIN (
                SELECT eqpt_id, COUNT(*) as count 
                FROM caseequipments 
                WHERE case_id IN (?) 
                GROUP BY eqpt_id
            ) ce ON e.eqpt_id = ce.eqpt_id
            SET e.eqpt_quantity = e.eqpt_quantity + ce.count
        `, [caseIds]);

        // 3. Delete
        await connection.query('DELETE FROM caseequipments WHERE case_id IN (?)', [caseIds]);
        await connection.query('DELETE FROM cases WHERE case_id IN (?)', [caseIds]);

        await connection.commit();
        res.json({ message: `Deleted ${caseIds.length} cases and restored inventory` });

    } catch (error) {
        await connection.rollback();
        console.error("Error deleting selected cases:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    } finally {
        connection.release();
    }
});

// Update case details (Admin)
router.put('/admin/cases/:caseId', async (req, res) => {
    const { caseId } = req.params;
    const {
        patient_id,
        patient_type,
        room_from,
        room_to,
        str_type_id, // ID of stretcher type
        equipments, // Array of equipment IDs
        notes
    } = req.body;

    // Start transaction since we might update cases and caseequipments
    const connection = await pool.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Update cases table
        const updateQuery = `
            UPDATE cases 
            SET case_patient_id = ?, 
                case_patient_type = ?, 
                case_room_from = ?, 
                case_room_to = ?, 
                str_type_id = ?, 
                case_notes = ?
            WHERE case_id = ?`;
        
        await connection.query(updateQuery, [
            patient_id,
            patient_type,
            room_from,
            room_to,
            str_type_id,
            notes,
            caseId
        ]);

        // 2. Update equipments (Delete old, Insert new)
        // Note: Ideally we should handle quantity return/deduct logic if equipments change, 
        // but for simplicity in admin edit, we might reset it. 
        // OR better: Just replace the associations. 
        // For a robust app, we'd adjust stock. Assuming simple logic for now: 
        // Just update the reference. Equipment stock management might be out of scope for this specific 'edit' request unless specified.
        // However, if we change equipments, we should update caseequipments table.

        if (equipments && Array.isArray(equipments)) {
             await connection.query('DELETE FROM caseequipments WHERE case_id = ?', [caseId]);
             for (const eqId of equipments) {
                 await connection.query('INSERT INTO caseequipments (case_id, eqpt_id) VALUES (?, ?)', [caseId, eqId]);
             }
        }

        await connection.commit();
        res.json({ message: 'Case updated successfully' });

    } catch (error) {
        await connection.rollback();
        console.error("Error updating case:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    } finally {
        connection.release();
    }
});

// Get all porters with case counts (Admin) - role_id=3 is porter
router.get('/admin/porters', async (req, res) => {
    try {
        const [porters] = await pool.query(`
            SELECT 
                u.user_num,
                u.user_username,
                u.user_fname,
                u.user_lname,
                u.user_phone,
                u.user_email,
                u.user_profile_image,
                r.role_name,
                (SELECT COUNT(*) FROM recordhistory rh WHERE rh.rhis_assigned_porter = u.user_num) as completed_cases,
                (SELECT COUNT(*) FROM cases c WHERE c.case_assigned_porter = u.user_num AND c.case_status = 'in_progress') as active_cases
            FROM users u
            LEFT JOIN roles r ON u.role_id = r.role_id
            WHERE u.role_id = 3
            ORDER BY completed_cases DESC
        `);

        res.json(porters);
    } catch (error) {
        console.error("Error fetching porters:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Get all nurses (Admin) - role_id=2 is nurse
router.get('/admin/nurses', async (req, res) => {
    try {
        const [nurses] = await pool.query(`
            SELECT 
                u.user_num,
                u.user_username,
                u.user_fname,
                u.user_lname,
                u.user_phone,
                u.user_email,
                u.user_profile_image,
                r.role_name,
                (SELECT COUNT(*) FROM cases c WHERE c.case_requested_by = u.user_num) as created_cases
            FROM users u
            LEFT JOIN roles r ON u.role_id = r.role_id
            WHERE u.role_id = 2
            ORDER BY created_cases DESC
        `);

        res.json(nurses);
    } catch (error) {
        console.error("Error fetching nurses:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

// Delete User (Admin)
router.delete('/admin/users/:userId', async (req, res) => {
    const { userId } = req.params;
    const { reason } = req.body;

    console.log(`Admin deleting user ${userId}. Reason: ${reason}`);

    try {
        // Delete from users table
        // Note: If foreign keys exist (e.g. cases created by this user), 
        // this might fail unless ON DELETE CASCADE is set or we handle it.
        // For now, attempting direct delete.
        const [result] = await pool.query('DELETE FROM users WHERE user_num = ?', [userId]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error("Error deleting user:", error);
        res.status(500).json({ message: 'Cannot delete user (might be linked to cases)', error: error.message });
    }
});

// Get dashboard statistics (Admin)
router.get('/admin/dashboard/stats', async (req, res) => {
    try {
        // Get case counts
        const [[{ total_cases }]] = await pool.query(`
            SELECT COUNT(*) as total_cases FROM cases
        `);
        const [[{ pending_cases }]] = await pool.query(`
            SELECT COUNT(*) as pending_cases FROM cases WHERE case_status = 'pending'
        `);
        const [[{ in_progress_cases }]] = await pool.query(`
            SELECT COUNT(*) as in_progress_cases FROM cases WHERE case_status = 'in_progress'
        `);
        const [[{ completed_today }]] = await pool.query(`
            SELECT COUNT(*) as completed_today FROM recordhistory 
            WHERE DATE(rhis_completed_at) = CURDATE()
        `);
        const [[{ completed_total }]] = await pool.query(`
            SELECT COUNT(*) as completed_total FROM recordhistory
        `);

        // Get porter counts
        const [[{ total_porters }]] = await pool.query(`
            SELECT COUNT(*) as total_porters FROM users WHERE role_id = 3
        `);
        const [[{ total_nurses }]] = await pool.query(`
            SELECT COUNT(*) as total_nurses FROM users WHERE role_id = 2
        `);

        // Get today's cases
        const [[{ today_cases }]] = await pool.query(`
            SELECT COUNT(*) as today_cases FROM cases 
            WHERE DATE(case_created_at) = CURDATE()
        `);

        // Get top porters (most completed cases)
        const [topPorters] = await pool.query(`
            SELECT 
                u.user_fname,
                u.user_lname,
                COUNT(r.rhis_id) as case_count
            FROM users u
            LEFT JOIN recordhistory r ON r.rhis_assigned_porter = u.user_num
            WHERE u.role_id = 3
            GROUP BY u.user_num
            ORDER BY case_count DESC
            LIMIT 5
        `);

        // Get ER cases count (emergency)
        const [[{ er_pending }]] = await pool.query(`
            SELECT COUNT(*) as er_pending FROM cases 
            WHERE case_patient_type LIKE 'ER%' AND case_status = 'pending'
        `);

        res.json({
            cases: {
                total: total_cases,
                pending: pending_cases,
                in_progress: in_progress_cases,
                completed_today: completed_today,
                completed_total: completed_total,
                today_new: today_cases,
                er_pending: er_pending
            },
            staff: {
                porters: total_porters,
                nurses: total_nurses
            },
            topPorters: topPorters
        });
    } catch (error) {
        console.error("Error fetching dashboard stats:", error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
});

module.exports = router;
