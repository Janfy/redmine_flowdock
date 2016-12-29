class FlowdockRenderer
  include Redmine::I18n
  include IssuesHelper
  include CustomFieldsHelper

  def notes_to_html(journal)
    if journal && journal.private_notes
      "<p>#{l(:private_note)}</p>"
    elsif journal && journal.notes
      textilizable(journal.notes, :headings => false)
    else
      ""
    end
  end

  def details_to_html(journal)
    begin
      html_list = journal_details(journal.details).map { |detail| "<li>#{detail}</li>" }
      "<ul>#{html_list.join}</ul>"
    rescue => ex
      ""
    end
  end

  def description_to_html(text)
    textilizable(text, :headings => false)
  end

  protected

  def journal_details(details)
    details_to_strings(details, true)
  end
end
