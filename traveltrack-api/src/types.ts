export type TravelRequestStatus = 'pending' | 'approved'

export interface TravelRequest {
  id: string
  employee: string
  destination: string
  days: number
  status: TravelRequestStatus
  createdAt: string
  approvedAt?: string
}
