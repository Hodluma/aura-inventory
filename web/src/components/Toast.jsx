import React, { useEffect } from 'react'

export default function Toast({ toast, onDismiss }) {
  useEffect(() => {
    const timer = setTimeout(() => onDismiss(toast.id), 3500)
    return () => clearTimeout(timer)
  }, [toast.id, onDismiss])

  return (
    <div className={['toast', toast.type].join(' ')}>
      <span>{toast.message}</span>
      <button onClick={() => onDismiss(toast.id)}>×</button>
    </div>
  )
}
