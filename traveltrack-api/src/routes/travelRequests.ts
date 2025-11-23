import { Router } from 'express'
import { z } from 'zod'
import { store } from '../store.js'
import type { TravelRequest } from '../types.js'

const router = Router()

const createSchema = z.object({
  employee: z.string().min(1),
  destination: z.string().min(1),
  days: z.number().int().positive()
})

router.post('/api/travel-requests', (req, res) => {
  const parse = createSchema.safeParse(req.body)
  if (!parse.success) {
    return res.status(400).json({ error: 'Invalid payload', details: parse.error.flatten() })
  }
  const { employee, destination, days } = parse.data
  const id = crypto.randomUUID()
  const now = new Date().toISOString()
  const tr: TravelRequest = { id, employee, destination, days, status: 'pending', createdAt: now }
  store.add(tr)
  res.status(201).json(tr)
})

router.get('/api/travel-requests', (_req, res) => {
  res.json(store.list())
})

router.patch('/api/travel-requests/:id/approve', (req, res) => {
  const { id } = req.params
  const existing = store.get(id)
  if (!existing) return res.status(404).json({ error: 'Not found' })
  if (existing.status === 'approved') return res.status(409).json({ error: 'Already approved' })
  const approved = store.update(id, { status: 'approved', approvedAt: new Date().toISOString() })
  res.json(approved)
})

export default router
