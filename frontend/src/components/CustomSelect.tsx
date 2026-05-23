import { useState, useEffect, useRef } from 'react'

interface SelectOption {
  value: string
  label: string
}

interface CustomSelectProps {
  value: string
  onChange: (value: string) => void
  options: SelectOption[]
  placeholder?: string
  className?: string
}

export default function CustomSelect({ 
  value, 
  onChange, 
  options, 
  placeholder = 'Select...',
  className = ''
}: CustomSelectProps) {
  const [isOpen, setIsOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const selectedOption = options.find(o => o.value === value)

  return (
    <div className={`relative ${className}`} ref={ref}>
      <button
        type="button"
        className="w-full bg-secondary text-text-primary rounded-lg px-3 py-2 border border-separator hover:border-elevated focus:border-accent focus:ring-1 focus:ring-accent outline-none text-sm text-left flex items-center justify-between"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className={selectedOption ? 'text-text-primary' : 'text-text-tertiary'}>
          {selectedOption?.label || placeholder}
        </span>
        <svg 
          className={`w-4 h-4 text-text-secondary transition-transform ${isOpen ? 'rotate-180' : ''}`} 
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-50 w-full mt-1 bg-secondary rounded-lg shadow-xl border border-separator max-h-60 overflow-auto">
          {options.map(option => (
            <button
              key={option.value}
              type="button"
              className={`w-full px-3 py-2.5 text-sm text-left hover:bg-tertiary transition-colors ${
                option.value === value 
                  ? 'bg-accent/20 text-accent' 
                  : 'text-text-primary'
              }`}
              onClick={() => {
                onChange(option.value)
                setIsOpen(false)
              }}
            >
              {option.label}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
