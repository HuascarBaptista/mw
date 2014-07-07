# -*- encoding : utf-8 -*-
class Ftp < ActiveRecord::Base
  self.table_name = "ftp"
  validates :host, :uniqueness=> true
end

