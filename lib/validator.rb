# encoding: UTF-8
# Clase Validator
class Validator
  def self.valid_date(date)
    date =~ /^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])$/ ? true :
    false
  end

  def self.valid_limit(limit)
    limit.to_i > 0 && limit.to_i <= 365
  end

  def self.valid_status(status)
    %w(approved pending all).include?(status)
  end

  def self.valid_params(params,valid_ones)
    valid_params =
      params.keys.map do |k|
        valid_ones.include?(k.to_s)
      end
    valid_params.all?
  end
end
