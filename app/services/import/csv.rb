require 'csv'

# @note The CSV must contain: amount, description and date (YYYY-MM-DD)
# @note the amount must be the full value (so $100 would be 100)

class Import::Csv
  def initialize(path, ynab_account_id)
    @path = path
    @ynab_account_id = ynab_account_id
  end

  def import
    transactions_to_create = []

    ::CSV.foreach(@path, headers: true) do |transaction|
      transaction = transaction.to_h.symbolize_keys
      transactions_to_create << {
        id: import_id(transaction),
        amount: (transaction[:amount].to_f * 1000).to_i,
        payee_name: transaction[:description],
        date: Date.parse(transaction[:date])
      }
    end

    YNAB::BulkTransactionCreator.new(transactions_to_create, account_id: @ynab_account_id).create
  end

  private

  def import_id(transaction)
    key = ['Fintech-To-YNAB', transaction[:amount], transaction[:date]].join(':')
    @_import_ids ||= Hash.new
    @_import_ids[key] ||= 0
    @_import_ids[key] += 1
    key + ":#{@_import_ids[key]}"
  end

end
