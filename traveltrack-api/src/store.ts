import type { TravelRequest } from './types'

const db: { requests: TravelRequest[] } = { requests: [] }

export const store = {
  list: () => db.requests,
  get: (id: string) => db.requests.find(r => r.id === id),
  add: (r: TravelRequest) => { db.requests.push(r); return r },
  update: (id: string, patch: Partial<TravelRequest>) => {
    const idx = db.requests.findIndex(r => r.id === id)
    if (idx === -1) return undefined
    db.requests[idx] = { ...db.requests[idx], ...patch }
    return db.requests[idx]
  }
}
