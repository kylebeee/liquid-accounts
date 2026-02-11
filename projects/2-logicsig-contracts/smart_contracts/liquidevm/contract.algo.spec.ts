import { TestExecutionContext } from '@algorandfoundation/algorand-typescript-testing'
import { describe, expect, it } from 'vitest'
import { Liquidevm } from './contract.algo'

describe('Liquidevm contract', () => {
  const ctx = new TestExecutionContext()
  it('Logs the returned value when sayHello is called', () => {
    const contract = ctx.contract.create(Liquidevm)

    const result = contract.hello('Sally')

    expect(result).toBe('Hello, Sally')
  })
})
